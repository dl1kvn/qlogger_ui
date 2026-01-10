import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import '../utils/morse.dart';
import '../services/ble/ble_service.dart';
import '../services/ble/ble_service_factory.dart';
import '../services/ble/ble_device.dart';

class BluetoothController extends GetxController {
  RxBool isScanning = false.obs;
  RxString deviceName = "Not Connected".obs;
  RxBool isConnected = false.obs;
  RxList<BleDevice> scanResults = <BleDevice>[].obs;

  late final BleService _bleService;
  StreamSubscription<List<BleDevice>>? _scanSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // CW speed (WPM) - Default 26 (range 16-36)
  RxInt cwSpeed = 26.obs;

  @override
  void onInit() {
    super.onInit();
    _bleService = BleServiceFactory.create();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    try {
      await _bleService.initialize();

      // Listen to scan results
      _scanSubscription = _bleService.scanResults.listen((results) {
        scanResults.assignAll(results);
      });

      // Listen to scanning state
      _scanningSubscription = _bleService.isScanning.listen((scanning) {
        isScanning.value = scanning;
      });

      // Listen to connection state
      _connectionSubscription = _bleService.connectionState.listen((connected) {
        isConnected.value = connected;
        if (connected) {
          deviceName.value = _bleService.connectedDeviceName;
        } else {
          deviceName.value = "Not Connected";
        }
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
      // Request Bluetooth permissions (mobile only)
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
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
      }

      scanResults.clear();
      await _bleService.startScan(timeout: const Duration(seconds: 10));
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
      _bleService.stopScan();
    } catch (e) {
      print('Stop scan error: $e');
    }
  }

  Future<void> connect(BleDevice device) async {
    try {
      final success = await _bleService.connect(device);

      if (success) {
        Get.snackbar(
          'Success',
          'Connected to ${device.displayName}',
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

  Future<void> disconnect() async {
    try {
      await _bleService.disconnect();
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// Send a string as Morse code to the ESP32
  Future<bool> sendMorseString(String data) async {
    if (!isConnected.value) {
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
      return await _bleService.writeData(bytes);
    } catch (e) {
      print('Send error: $e');
      return false;
    }
  }

  /// Send raw string without Morse encoding
  Future<bool> sendRawString(String data) async {
    if (!isConnected.value) {
      return false;
    }

    try {
      List<int> bytes = utf8.encode(data);
      return await _bleService.writeData(bytes);
    } catch (e) {
      print('Send raw error: $e');
      return false;
    }
  }

  /// Send speed change to Arduino (format: _XX#)
  Future<bool> sendSpeedChange() async {
    if (!isConnected.value) {
      return false;
    }

    try {
      // Convert WPM to milliseconds per dit: 1200 / WPM
      final speedMs = (1200 / cwSpeed.value).round();
      final data = '_${speedMs}#';

      print('Sending speed: $data');

      final bytes = utf8.encode(data);
      return await _bleService.writeData(bytes);
    } catch (e) {
      print('Send speed error: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _scanningSubscription?.cancel();
    _connectionSubscription?.cancel();
    _bleService.dispose();
    super.onClose();
  }
}
