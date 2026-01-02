/*
 * Morse Q BLE - CW Keyer with Bluetooth Low Energy
 * - BLE RX buffered, frames terminated with '#'
 * - Format per frame: "<morsetext>_<speed>#"
 *   morsetext uses: '.' dit, '-' dah, '|' letter separator, ' ' word separator
 * - Non-blocking Morse playback (millis-based), standard timing:
 *     dit=1, dah=3, inter-element=1, letter gap=3, word gap=7
 * - FIFO queue (ring buffer) for multiple incoming frames (e.g. repeated CQ)
 * - Paddle press aborts playback immediately
 */

#include "BLEDevice.h"
#include "BLEServer.h"
#include "BLEUtils.h"
#include "BLE2902.h"

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Pins
int LPin = 23;      // Left paddle input
int RPin = 19;      // Right paddle input
int relayPin = 16;  // keying output (HIGH=ON, LOW=OFF per your logic)

// Speed (ms per dit) - can be updated per frame
volatile uint32_t speedMs = 49;

// Keyer defines
#define DIT_L      0x01
#define DAH_L      0x02
#define DIT_PROC   0x04
#define IAMBICB    0x10

char keyerControl;
char keyerState;

enum KSTYPE {
  IDLE,
  CHK_DIT,
  CHK_DAH,
  KEYED_PREP,
  KEYED,
  INTER_ELEMENT,
};

// BLE variables
BLEServer *pServer = nullptr;
BLECharacteristic *pCharacteristic = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// RX buffer for received BLE writes
static String bleReceivedData;

// -----------------------------
// Queue (ring buffer) — DECLARE TYPES FIRST
// -----------------------------
struct MorseFrame {
  String morse;
  uint32_t speed;
};

static const uint8_t QSIZE = 8; // adjust as needed
static MorseFrame q[QSIZE];
static uint8_t qHead = 0;
static uint8_t qTail = 0;
static uint8_t qCount = 0;

// Policy: drop oldest when full (good for repeated CQ)
static void queuePushDropOldest(const String& morse, uint32_t spd) {
  if (qCount >= QSIZE) {
    // drop oldest
    qHead = (qHead + 1) % QSIZE;
    qCount--;
  }
  q[qTail].morse = morse;
  q[qTail].speed = spd;
  qTail = (qTail + 1) % QSIZE;
  qCount++;
}

static bool queuePop(MorseFrame& out) {
  if (qCount == 0) return false;
  out = q[qHead];
  q[qHead].morse = ""; // free String memory early (optional)
  qHead = (qHead + 1) % QSIZE;
  qCount--;
  return true;
}

// -----------------------------
// Relay + timing helpers
// -----------------------------
static bool relayDown = false;

static inline void relaySet(bool down) {
  relayDown = down;
  digitalWrite(relayPin, down ? HIGH : LOW);
}

static inline bool paddlesPressed() {
  return (digitalRead(LPin) == LOW) || (digitalRead(RPin) == LOW);
}

static inline bool timeReached(uint32_t t) {
  return (int32_t)(millis() - t) >= 0; // wrap-safe
}

static inline void scheduleIn(uint32_t deltaMs, uint32_t &nextAtMs) {
  nextAtMs = millis() + deltaMs;
}

// -----------------------------
// Non-blocking Morse player
// -----------------------------
static bool morsePlaying = false;
static String morseBuf;
static int morseIdx = 0;
static uint32_t playSpeed = 49;
static uint32_t nextAtMs = 0;

static void startMorsePlayback(const String& s, uint32_t spd) {
  morseBuf = s;
  morseIdx = 0;

  playSpeed = spd;
  if (playSpeed < 20) playSpeed = 49;
  if (playSpeed > 200) playSpeed = 200;

  morsePlaying = true;
  relaySet(false);
  scheduleIn(0, nextAtMs);
}

// Standard timing with separators:
// - After each dot/dash we already schedule 1-dit inter-element gap.
// - For letter gap total 3 dits => add +2 dits on '|'
// - For word gap total 7 dits => add +6 dits on ' '
static void morseTick() {
  if (!morsePlaying) return;

  // Paddle abort
  if (paddlesPressed()) {
    morsePlaying = false;
    relaySet(false);
    return;
  }

  if (!timeReached(nextAtMs)) return;

  // Finished current buffer
  if (morseIdx >= (int)morseBuf.length()) {
    morsePlaying = false;
    relaySet(false);

    // Start next queued frame (if any)
    MorseFrame next;
    if (queuePop(next)) {
      startMorsePlayback(next.morse, next.speed);
    }
    return;
  }

  char c = morseBuf[morseIdx];

  if (c == '.' || c == '-') {
    // two-phase: DOWN then UP + 1 dit gap
    if (!relayDown) {
      relaySet(true);
      scheduleIn((c == '.') ? playSpeed : (playSpeed * 3), nextAtMs);
    } else {
      relaySet(false);
      morseIdx++;
      scheduleIn(playSpeed, nextAtMs); // element gap 1 dit
    }
    return;
  }

  // Separators / unknown: ensure key up
  relaySet(false);

  if (c == '|') {
    morseIdx++;
    scheduleIn(playSpeed * 2, nextAtMs); // +2 dits (letter gap total 3)
  } else if (c == ' ') {
    morseIdx++;
    scheduleIn(playSpeed * 6, nextAtMs); // +6 dits (word gap total 7)
  } else {
    morseIdx++;
    scheduleIn(playSpeed, nextAtMs);
  }
}

// -----------------------------
// BLE Callbacks
// -----------------------------
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("BLE Client Connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("BLE Client Disconnected");
  }
};

class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    // Your lib returns Arduino String here
    String v = pCharacteristic->getValue();
    if (v.length() > 0) {
      bleReceivedData += v;
    }
  }
};

// -----------------------------
// Keyer helpers
// -----------------------------
void update_PaddleLatch() {
  if (digitalRead(RPin) == LOW) keyerControl |= DIT_L;
  if (digitalRead(LPin) == LOW) keyerControl |= DAH_L;
}

// -----------------------------
// Parse and queue frames from RX buffer
// Format: "<morse>_<speed>#"
// -----------------------------
static void processBleFramesNonBlocking() {
  int hashPos;
  while ((hashPos = bleReceivedData.indexOf('#')) >= 0) {
    String frame = bleReceivedData.substring(0, hashPos);
    bleReceivedData.remove(0, hashPos + 1);

    frame.trim();
    if (frame.length() == 0) continue;

    int usPos = frame.indexOf('_');

    // No '_' -> treat as morse with current speedMs
    if (usPos < 0) {
      queuePushDropOldest(frame, speedMs);

      if (!morsePlaying) {
        MorseFrame next;
        if (queuePop(next)) startMorsePlayback(next.morse, next.speed);
      }
      continue;
    }

    // Split at '_'
    String left = frame.substring(0, usPos);
    String right = frame.substring(usPos + 1);
    left.trim();
    right.trim();

    // Parse speed
    uint32_t parsed = (uint32_t) right.toInt();
    bool speedValid = (parsed >= 20 && parsed <= 200);

    // CASE 1: speed-only frame like "_49"
    if (left.length() == 0) {
      if (speedValid) {
        // Update only the "base" speed (paddle + future playbacks),
        // do NOT affect current playback.
        speedMs = parsed;

        Serial.print("Speed set (future): ");
        Serial.println(speedMs);
      }
      continue;
    }

    // CASE 2: morse + speed like "CQ|DE|..._49"
    uint32_t frameSpeed = speedValid ? parsed : speedMs;

    // Enqueue with its own speed (playback uses frameSpeed when it starts)
    queuePushDropOldest(left, frameSpeed);

    // Update paddle speed only if system is idle (no current playback and nothing queued before this frame)
    // At this point we already pushed, so "idle" means we were idle before pushing:
    // We can approximate by: if not currently playing AND queue count == 1 (this frame is the only one).
    if (!morsePlaying && qCount == 1 && speedValid) {
      speedMs = frameSpeed;
      Serial.print("Speed set (idle, from frame): ");
      Serial.println(speedMs);
    }

    // If idle, start immediately
    if (!morsePlaying) {
      MorseFrame next;
      if (queuePop(next)) startMorsePlayback(next.morse, next.speed);
    }

    Serial.print("Enqueued: ");
    Serial.print(left);
    Serial.print(" speed=");
    Serial.println(frameSpeed);
  }
}


void setup() {
  Serial.begin(115200);
  Serial.println("Morse Q BLE starting...");

  pinMode(relayPin, OUTPUT);
  relaySet(false);

  // Stable paddle inputs
  pinMode(LPin, INPUT_PULLUP);
  pinMode(RPin, INPUT_PULLUP);

  keyerState = IDLE;
  keyerControl = 0;

  // Initialize BLE
  BLEDevice::init("qlogger");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_WRITE_NR
  );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("Ready");

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE Ready! Device name: qlogger");
}

void loop() {
  static long ktimer;

  // 1) Consume BLE frames quickly (non-blocking)
  processBleFramesNonBlocking();

  // 2) Advance queued morse playback (non-blocking)
  morseTick();

  // 3) Prevent relay fights: keyer must be silent during playback
  if (morsePlaying) {
    return;
  }

  // ---- Paddle keyer state machine ----
  switch (keyerState) {
    case IDLE:
      if ((digitalRead(LPin) == LOW) ||
          (digitalRead(RPin) == LOW) ||
          (keyerControl & 0x03)) {
        update_PaddleLatch();
        keyerState = CHK_DIT;
      }
      break;

    case CHK_DIT:
      if (keyerControl & DIT_L) {
        keyerControl |= DIT_PROC;
        ktimer = (long)speedMs;
        keyerState = KEYED_PREP;
      } else {
        keyerState = CHK_DAH;
      }
      break;

    case CHK_DAH:
      if (keyerControl & DAH_L) {
        ktimer = (long)speedMs * 3;
        keyerState = KEYED_PREP;
      } else {
        keyerState = IDLE;
      }
      break;

    case KEYED_PREP:
      relaySet(true);
      ktimer += millis();
      keyerControl &= ~(DIT_L + DAH_L);
      keyerState = KEYED;
      break;

    case KEYED:
      if (millis() > (uint32_t)ktimer) {
        relaySet(false);
        ktimer = millis() + speedMs;
        keyerState = INTER_ELEMENT;
      } else if (keyerControl & IAMBICB) {
        update_PaddleLatch();
      }
      update_PaddleLatch();
      break;

    case INTER_ELEMENT:
      update_PaddleLatch();
      if (millis() > (uint32_t)ktimer) {
        if (keyerControl & DIT_PROC) {
          keyerControl &= ~(DIT_L + DIT_PROC);
          keyerState = CHK_DAH;
        } else {
          keyerControl &= ~(DAH_L);
          keyerState = IDLE;
        }
      }
      break;
  }

  // 4) Re-advertise on disconnect (non-blocking)
  if (!deviceConnected && oldDeviceConnected) {
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
