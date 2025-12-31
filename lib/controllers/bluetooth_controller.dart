import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../utils/morse.dart';

class BluetoothController extends GetxController {
  final FlutterBlueClassic flutterBlue = FlutterBlueClassic();

  Rx<BluetoothAdapterState> adapterState = BluetoothAdapterState.unknown.obs;
  RxBool isScanning = false.obs;
  RxString deviceName = "Not Connected".obs;
  RxBool isConnected = false.obs;
  RxSet<BluetoothDevice> scanResults = <BluetoothDevice>{}.obs;

  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _scanningStateSubscription;
  BluetoothConnection? connection;

  // CW speed (WPM) - Default 100 wie in fastiotalogger
  RxInt cwSpeed = 100.obs;

  @override
  void onInit() {
    super.onInit();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    try {
      // Get initial adapter state
      adapterState.value = await flutterBlue.adapterStateNow;

      // Listen to adapter state changes
      _adapterStateSubscription = flutterBlue.adapterState.listen((state) {
        adapterState.value = state;
      });

      // Listen to scan results
      _scanSubscription = flutterBlue.scanResults.listen((device) {
        scanResults.add(device);
      });

      // Listen to scanning state
      _scanningStateSubscription = flutterBlue.isScanning.listen((scanning) {
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
      flutterBlue.startScan();
    } catch (e) {
      print('Start scan error: $e');
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    // Request all required Bluetooth permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // Check if all permissions are granted
    return statuses.values.every((status) => status.isGranted);
  }

  void stopScan() {
    try {
      flutterBlue.stopScan();
    } catch (e) {
      print('Stop scan error: $e');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      connection = await flutterBlue.connect(device.address);

      if (connection != null && connection!.isConnected) {
        isConnected.value = true;
        deviceName.value = device.name ?? "Unknown Device";

        Get.snackbar(
          'Success',
          'Connected to ${device.name}',
          colorText: Colors.white,
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      print('Connection error: $e');
      connection?.dispose();
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
      connection?.dispose();
      connection = null;
      isConnected.value = false;
      deviceName.value = "Not Connected";
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  void turnOnBluetooth() {
    flutterBlue.turnOn();
  }

  /// Send a string as Morse code to the ESP32
  /// Mit Chunking um ESP nicht zu überlasten
  Future<bool> sendMorseString(String data) async {
    if (!isConnected.value || connection == null) return false;

    try {
      late Morse morse = Morse(data.trim() + ' ', message: data.trim() + ' ');
      String speed = (cwSpeed.value + 15).toString();
      String encodedMessage = morse.encode(data);
      data = encodedMessage + '_' + speed + '#';

      print('Sending CW: $data');

      if (data.length > 0) {
        List<int> bytes = utf8.encode(data);

        // Chunked senden um ESP nicht zu überlasten
        const int chunkSize = 20; // Kleine Chunks für Bluetooth
        int offset = 0;

        while (offset < bytes.length) {
          final end = (offset + chunkSize < bytes.length)
              ? offset + chunkSize
              : bytes.length;

          connection?.output.add(
            Uint8List.fromList(bytes.sublist(offset, end)),
          );
          await connection?.output.allSent;
          offset = end;

          // Kleine Pause damit ESP verarbeiten kann
          if (offset < bytes.length) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Send error: $e');
      return false;
    }
  }

  /// Send raw string without Morse encoding
  bool sendRawString(String data) {
    if (!isConnected.value || connection == null) {
      return false;
    }

    try {
      List<int> bytes = utf8.encode(data);
      connection?.output.add(Uint8List.fromList(bytes));
      connection?.output.allSent;
      return true;
    } catch (e) {
      print('Send raw error: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _scanningStateSubscription?.cancel();
    connection?.dispose();
    super.onClose();
  }
}
