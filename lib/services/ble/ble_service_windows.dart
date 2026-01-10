import 'dart:async';
import 'dart:typed_data';
import 'package:win_ble/win_ble.dart' as win_ble;
import 'package:win_ble/win_file.dart';
import 'ble_service.dart';
import 'ble_device.dart';

const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

class BleServiceWindows implements BleService {
  String? _connectedDeviceAddress;
  String? _connectedServiceId;
  String? _writeCharacteristicId;

  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  final List<BleDevice> _discoveredDevices = [];

  String _connectedDeviceName = '';
  bool _isConnected = false;
  bool _isCurrentlyScanning = false;

  @override
  Stream<List<BleDevice>> get scanResults => _scanResultsController.stream;

  @override
  Stream<bool> get isScanning => _isScanningController.stream;

  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  @override
  String get connectedDeviceName => _connectedDeviceName;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initialize() async {
    await win_ble.WinBle.initialize(
      serverPath: await WinServer.path(),
      enableLog: false,
    );

    // Listen for device discovery
    win_ble.WinBle.scanStream.listen((device) {
      // Check if device already exists
      final existingIndex = _discoveredDevices.indexWhere(
        (d) => d.id == device.address,
      );

      final bleDevice = BleDevice(
        id: device.address,
        name: device.name,
        nativeDevice: device,
      );

      if (existingIndex >= 0) {
        _discoveredDevices[existingIndex] = bleDevice;
      } else {
        _discoveredDevices.add(bleDevice);
      }

      _scanResultsController.add(List.from(_discoveredDevices));
    });

    // Listen for connection state changes
    win_ble.WinBle.connectionStreamOf(_connectedDeviceAddress ?? '').listen((connected) {
      if (!connected) {
        _handleDisconnection();
      }
    });
  }

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    _discoveredDevices.clear();
    _scanResultsController.add([]);
    _isCurrentlyScanning = true;
    _isScanningController.add(true);

    win_ble.WinBle.startScanning();

    // Auto-stop after timeout
    Future.delayed(timeout, () {
      if (_isCurrentlyScanning) {
        stopScan();
      }
    });
  }

  @override
  void stopScan() {
    win_ble.WinBle.stopScanning();
    _isCurrentlyScanning = false;
    _isScanningController.add(false);
  }

  @override
  Future<bool> connect(BleDevice device) async {
    try {
      final address = device.id;

      await win_ble.WinBle.connect(address);
      _connectedDeviceAddress = address;

      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      List<String> services = await win_ble.WinBle.discoverServices(address);

      // Find our service
      String? targetService;
      for (var service in services) {
        if (service.toLowerCase() == SERVICE_UUID.toLowerCase()) {
          targetService = service;
          break;
        }
      }

      // If exact service not found, use first available
      targetService ??= services.isNotEmpty ? services.first : null;

      if (targetService == null) {
        print('No services found');
        await win_ble.WinBle.disconnect(address);
        return false;
      }

      _connectedServiceId = targetService;

      // Discover characteristics
      List<win_ble.BleCharacteristic> chars = await win_ble.WinBle.discoverCharacteristics(
        address: address,
        serviceId: targetService,
      );

      // Find our characteristic
      _writeCharacteristicId = null;
      for (var char in chars) {
        if (char.uuid.toLowerCase() == CHARACTERISTIC_UUID.toLowerCase()) {
          _writeCharacteristicId = char.uuid;
          break;
        }
      }

      // If specific characteristic not found, try to find any writable one
      if (_writeCharacteristicId == null) {
        for (var char in chars) {
          if (char.properties.write == true ||
              char.properties.writeWithoutResponse == true) {
            _writeCharacteristicId = char.uuid;
            break;
          }
        }
      }

      _isConnected = true;
      _connectedDeviceName = device.displayName;
      _connectionStateController.add(true);

      // Set up connection state listener for this device
      win_ble.WinBle.connectionStreamOf(address).listen((connected) {
        if (!connected) {
          _handleDisconnection();
        }
      });

      return _writeCharacteristicId != null;
    } catch (e) {
      print('Windows BLE connection error: $e');
      return false;
    }
  }

  void _handleDisconnection() {
    _connectedDeviceAddress = null;
    _connectedServiceId = null;
    _writeCharacteristicId = null;
    _isConnected = false;
    _connectedDeviceName = '';
    _connectionStateController.add(false);
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDeviceAddress != null) {
      await win_ble.WinBle.disconnect(_connectedDeviceAddress!);
    }
    _handleDisconnection();
  }

  @override
  Future<bool> writeData(List<int> data) async {
    if (!_isConnected ||
        _connectedDeviceAddress == null ||
        _connectedServiceId == null ||
        _writeCharacteristicId == null) {
      return false;
    }

    try {
      await win_ble.WinBle.write(
        address: _connectedDeviceAddress!,
        service: _connectedServiceId!,
        characteristic: _writeCharacteristicId!,
        data: Uint8List.fromList(data),
        writeWithResponse: true,
      );

      return true;
    } catch (e) {
      print('Windows BLE write error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    if (_connectedDeviceAddress != null) {
      win_ble.WinBle.disconnect(_connectedDeviceAddress!);
    }
    win_ble.WinBle.dispose();
    _scanResultsController.close();
    _isScanningController.close();
    _connectionStateController.close();
  }
}
