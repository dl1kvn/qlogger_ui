import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/morse.dart';

// BLE UUIDs - must match Arduino code
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

class BluetoothController extends GetxController {
  RxBool isScanning = false.obs;
  RxString deviceName = "Not Connected".obs;
  RxBool isConnected = false.obs;
  RxList<ScanResult> scanResults = <ScanResult>[].obs;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // CW speed (WPM) - Default 26 (range 16-36)
  RxInt cwSpeed = 26.obs;

  @override
  void onInit() {
    super.onInit();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    try {
      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults.assignAll(results);
      });

      // Listen to scanning state
      _scanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        isScanning.value = scanning;
      });
    } catch (e) {
      print('Bluetooth init error: $e');
      Get.snackbar(
        'Error',
        'Bluetooth initialization failed: ${e.toString()}',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> startScan() async {
    try {
      // Request Bluetooth permissions
      final permissions = await _requestBluetoothPermissions();
      if (!permissions) {
        Get.snackbar(
          'Permission Required',
          'Bluetooth permissions are needed to scan for devices',
          colorText: Colors.white,
          backgroundColor: Colors.orange,
        );
        return;
      }

      scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      print('Start scan error: $e');
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void stopScan() {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      print('Stop scan error: $e');
    }
  }

  Future<void> connect(ScanResult result) async {
    try {
      final device = result.device;

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));

      // Listen for disconnection
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find our service and characteristic
      _writeCharacteristic = null;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              _writeCharacteristic = char;
              break;
            }
          }
        }
        if (_writeCharacteristic != null) break;
      }

      // If specific characteristic not found, try to find any writable one
      if (_writeCharacteristic == null) {
        for (var service in services) {
          for (var char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              _writeCharacteristic = char;
              break;
            }
          }
          if (_writeCharacteristic != null) break;
        }
      }

      _connectedDevice = device;
      isConnected.value = true;
      deviceName.value = device.platformName.isNotEmpty
          ? device.platformName
          : "Unknown Device";

      if (_writeCharacteristic != null) {
        Get.snackbar(
          'Success',
          'Connected to ${deviceName.value}',
          colorText: Colors.white,
          backgroundColor: Colors.green,
        );
      } else {
        Get.snackbar(
          'Warning',
          'Connected but no write characteristic found',
          colorText: Colors.white,
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      print('Connection error: $e');
      Get.snackbar(
        'Error',
        'Connection failed: ${e.toString()}',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    isConnected.value = false;
    deviceName.value = "Not Connected";
  }

  Future<void> disconnect() async {
    try {
      _connectionSubscription?.cancel();
      await _connectedDevice?.disconnect();
      _handleDisconnection();
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  void turnOnBluetooth() {
    FlutterBluePlus.turnOn();
  }

  /// Send a string as Morse code to the ESP32
  Future<bool> sendMorseString(String data) async {
    if (!isConnected.value || _writeCharacteristic == null) {
      return false;
    }

    try {
      final morse = Morse(data.trim(), message: data.trim());
      final encoded = morse.encode(data);
      // Convert WPM to milliseconds per dit: 1200 / WPM
      final speed = (1200 / cwSpeed.value).round().toString();
      data = '${encoded}_$speed#';

      print('Sending CW: $data');

      final bytes = utf8.encode(data);

      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      }

      return true;
    } catch (e) {
      print('Send error: $e');
      return false;
    }
  }

  /// Send raw string without Morse encoding
  Future<bool> sendRawString(String data) async {
    if (!isConnected.value || _writeCharacteristic == null) {
      return false;
    }

    try {
      List<int> bytes = utf8.encode(data);

      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      }

      return true;
    } catch (e) {
      print('Send raw error: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _scanningSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.onClose();
  }
}
