import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/simulation_setup_screen.dart' show simulationFrequency;

class MorseAudioService {
  static final MorseAudioService _instance = MorseAudioService._internal();
  factory MorseAudioService() => _instance;
  MorseAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Completer<void>? _playbackCompleter;

  // Morse code timing (in milliseconds)
  int _wpm = 20; // Words per minute
  int get _ditDuration => (1200 / _wpm).round();
  int get _dahDuration => _ditDuration * 3;
  int get _elementGap => _ditDuration; // Gap between dits/dahs
  int get _letterGap => _ditDuration * 3; // Gap between letters
  int get _wordGap => _ditDuration * 7; // Gap between words

  // Audio parameters
  final int _sampleRate = 44100;
  double get _frequency => simulationFrequency.value; // Hz - from simulation settings

  // Morse code dictionary
  static const Map<String, String> _morseCode = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    '/': '-..-.',
    ' ': ' ',
  };

  // Amateur radio callsign prefixes by region
  static const List<String> _prefixes = [
    'W',
    'K',
    'N',
    'AA',
    'AB',
    'AC',
    'AD',
    'AE',
    'AF',
    'AG',
    'AI',
    'AJ',
    'AK',
    'AL',
    'KA',
    'KB',
    'KC',
    'KD',
    'KE',
    'KF',
    'KG',
    'KI',
    'KJ',
    'KK',
    'KL',
    'KM',
    'KN',
    'WA',
    'WB',
    'WC',
    'WD',
    'WE',
    'WF',
    'WG',
    'WI',
    'WJ',
    'WK',
    'WL',
    'WM',
    'WN',
    'NA',
    'NB',
    'NC',
    'ND',
    'NE',
    'NF',
    'NG',
    'NI',
    'NJ',
    'NK',
    'NL',
    'NM',
    'NN',
    'G',
    'M',
    'GM',
    'GW',
    '2E',
    'EA',
    'F',
    'DL',
    'DJ',
    'DK',
    'PA',
    'ON',
    'OZ',
    'SM',
    'LA',
    'OH',
    'SP',
    'OK',
    'HA',
    'YO',
    'LZ',
    'YU',
    'I',
    'CT',
    'UA',
    'VK',
    'ZL',
    'JA',
    'JH',
    'JR',
    'HL',
    'BV',
    'BY',
    'VU',
    'ZS',
    'PY',
    'LU',
    'CE',
    'XE',
  ];

  void setWpm(int wpm) {
    _wpm = wpm.clamp(10, 40);
  }

  /// Generate a random amateur radio callsign
  String generateRandomCallsign() {
    final random = Random();
    final prefix = _prefixes[random.nextInt(_prefixes.length)];
    final digit = random.nextInt(10);

    // Generate 1-3 suffix letters
    final suffixLength = random.nextInt(3) + 1;
    final suffix = String.fromCharCodes(
      List.generate(suffixLength, (_) => 65 + random.nextInt(26)),
    );

    return '$prefix$digit$suffix';
  }

  /// Convert text to morse code string (dots and dashes)
  String textToMorse(String text) {
    return text
        .toUpperCase()
        .split('')
        .map((char) {
          return _morseCode[char] ?? '';
        })
        .join(' ');
  }

  /// Generate audio samples for a tone
  Uint8List _generateTone(int durationMs) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Uint8List(numSamples * 2); // 16-bit samples

    for (int i = 0; i < numSamples; i++) {
      // Apply envelope to avoid clicks
      double envelope = 1.0;
      final attackSamples = (_sampleRate * 0.005).round(); // 5ms attack
      final releaseSamples = (_sampleRate * 0.005).round(); // 5ms release

      if (i < attackSamples) {
        envelope = i / attackSamples;
      } else if (i > numSamples - releaseSamples) {
        envelope = (numSamples - i) / releaseSamples;
      }

      final sample =
          (sin(2 * pi * _frequency * i / _sampleRate) * 32767 * 0.5 * envelope)
              .round();
      samples[i * 2] = sample & 0xFF;
      samples[i * 2 + 1] = (sample >> 8) & 0xFF;
    }

    return samples;
  }

  /// Generate silence samples
  Uint8List _generateSilence(int durationMs) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    return Uint8List(numSamples * 2); // All zeros = silence
  }

  /// Generate WAV file bytes from morse code
  Uint8List _generateWavFromMorse(String text) {
    final List<Uint8List> audioChunks = [];

    // Lead-in silence to prevent audio player from cutting off the beginning
    audioChunks.add(_generateSilence(150)); // 150ms lead-in

    final upperText = text.toUpperCase();

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      final morse = _morseCode[char];

      if (morse == null) continue;

      if (char == ' ') {
        audioChunks.add(_generateSilence(_wordGap - _letterGap));
        continue;
      }

      for (int j = 0; j < morse.length; j++) {
        final element = morse[j];
        if (element == '.') {
          audioChunks.add(_generateTone(_ditDuration));
        } else if (element == '-') {
          audioChunks.add(_generateTone(_dahDuration));
        }

        // Add gap between elements (but not after last element)
        if (j < morse.length - 1) {
          audioChunks.add(_generateSilence(_elementGap));
        }
      }

      // Add letter gap (but not after last letter)
      if (i < upperText.length - 1 && upperText[i + 1] != ' ') {
        audioChunks.add(_generateSilence(_letterGap));
      }
    }

    // Combine all chunks
    final totalLength = audioChunks.fold<int>(
      0,
      (sum, chunk) => sum + chunk.length,
    );
    final audioData = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in audioChunks) {
      audioData.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // Create WAV header
    return _createWavFile(audioData);
  }

  /// Create a WAV file from raw audio data
  Uint8List _createWavFile(Uint8List audioData) {
    final fileSize = 44 + audioData.length;
    final wavFile = Uint8List(fileSize);
    final byteData = ByteData.view(wavFile.buffer);

    // RIFF header
    wavFile[0] = 0x52; // R
    wavFile[1] = 0x49; // I
    wavFile[2] = 0x46; // F
    wavFile[3] = 0x46; // F
    byteData.setUint32(4, fileSize - 8, Endian.little); // File size - 8
    wavFile[8] = 0x57; // W
    wavFile[9] = 0x41; // A
    wavFile[10] = 0x56; // V
    wavFile[11] = 0x45; // E

    // fmt chunk
    wavFile[12] = 0x66; // f
    wavFile[13] = 0x6D; // m
    wavFile[14] = 0x74; // t
    wavFile[15] = 0x20; // space
    byteData.setUint32(16, 16, Endian.little); // Chunk size
    byteData.setUint16(20, 1, Endian.little); // Audio format (PCM)
    byteData.setUint16(22, 1, Endian.little); // Num channels (mono)
    byteData.setUint32(24, _sampleRate, Endian.little); // Sample rate
    byteData.setUint32(28, _sampleRate * 2, Endian.little); // Byte rate
    byteData.setUint16(32, 2, Endian.little); // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    wavFile[36] = 0x64; // d
    wavFile[37] = 0x61; // a
    wavFile[38] = 0x74; // t
    wavFile[39] = 0x61; // a
    byteData.setUint32(40, audioData.length, Endian.little); // Data size

    // Audio data
    wavFile.setRange(44, 44 + audioData.length, audioData);

    return wavFile;
  }

  /// Play morse code for the given text
  Future<void> playMorse(String text) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;
    _playbackCompleter = Completer<void>();

    try {
      final wavData = _generateWavFromMorse(text);

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/morse_audio.wav');
      await tempFile.writeAsBytes(wavData);

      await _player.setFilePath(tempFile.path);
      await _player.play();

      // Wait for playback to complete
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } finally {
      _isPlaying = false;
      _playbackCompleter?.complete();
      _playbackCompleter = null;
    }
  }

  /// Play a random callsign and return it
  Future<String> playRandomCallsign() async {
    final callsign = generateRandomCallsign();
    await playMorse(callsign);
    return callsign;
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _playbackCompleter?.complete();
    _playbackCompleter = null;
  }

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}
