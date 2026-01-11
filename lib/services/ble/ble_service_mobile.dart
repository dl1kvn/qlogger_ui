import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';
import 'ble_device.dart';

const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

class BleServiceMobile implements BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  String _connectedDeviceName = '';
  bool _isConnected = false;

  @override
  Stream<List<BleDevice>> get scanResults => _scanResultsController.stream;

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  @override
  String get connectedDeviceName => _connectedDeviceName;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  @override
  Future<void> initialize() async {
    FlutterBluePlus.scanResults.listen((results) {
      final devices = results.map((r) => BleDevice(
        id: r.device.remoteId.str,
        name: r.device.platformName,
        nativeDevice: r,
      )).toList();
      _scanResultsController.add(devices);
    });
  }

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  @override
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  @override
  Future<bool> connect(BleDevice device) async {
    try {
      final scanResult = device.nativeDevice as ScanResult;
      final btDevice = scanResult.device;

      await btDevice.connect(timeout: const Duration(seconds: 10));

      _connectionSubscription?.cancel();
      _connectionSubscription = btDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services
      List<BluetoothService> services = await btDevice.discoverServices();

      // Find our service and characteristic
      _writeCharacteristic = null;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase()) {
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

      _connectedDevice = btDevice;
      _isConnected = true;
      _connectedDeviceName = btDevice.platformName.isNotEmpty
          ? btDevice.platformName
          : "Unknown Device";
      _connectionStateController.add(true);

      return _writeCharacteristic != null;
    } catch (e) {
      print('Mobile BLE connection error: $e');
      return false;
    }
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _isConnected = false;
    _connectedDeviceName = '';
    _connectionStateController.add(false);
  }

  @override
  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _handleDisconnection();
  }

  @override
  Future<bool> writeData(List<int> data) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(data, withoutResponse: false);
      } else {
        await _writeCharacteristic!.write(data, withoutResponse: true);
      }
      return true;
    } catch (e) {
      print('Mobile BLE write error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _connectedDevice?.disconnect();
    _scanResultsController.close();
    _connectionStateController.close();
  }
}
