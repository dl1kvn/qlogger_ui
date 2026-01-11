import 'dart:async';
import 'ble_device.dart';

/// Abstract BLE service interface for platform-specific implementations
abstract class BleService {
  /// Stream of discovered devices during scanning
  Stream<List<BleDevice>> get scanResults;

  /// Stream of scanning state
  Stream<bool> get isScanning;

  /// Stream of connection state
  Stream<bool> get connectionState;

  /// Currently connected device name
  String get connectedDeviceName;

  /// Whether currently connected
  bool get isConnected;

  /// Check if Bluetooth adapter is enabled
  Future<bool> isBluetoothEnabled();

  /// Initialize the BLE service
  Future<void> initialize();

  /// Start scanning for BLE devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)});

  /// Stop scanning
  void stopScan();

  /// Connect to a device
  Future<bool> connect(BleDevice device);

  /// Disconnect from current device
  Future<void> disconnect();

  /// Write data to the connected device
  Future<bool> writeData(List<int> data);

  /// Dispose resources
  void dispose();
}
