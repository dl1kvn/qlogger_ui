/// Platform-agnostic BLE device representation
class BleDevice {
  final String id;
  final String name;
  final dynamic nativeDevice;

  BleDevice({
    required this.id,
    required this.name,
    this.nativeDevice,
  });

  String get displayName => name.isNotEmpty ? name : 'Unknown Device';
}
