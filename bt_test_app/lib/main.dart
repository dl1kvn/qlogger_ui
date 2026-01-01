import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/morse.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Morse Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BleTestScreen(),
    );
  }
}

class BleTestScreen extends StatefulWidget {
  const BleTestScreen({super.key});

  @override
  State<BleTestScreen> createState() => _BleTestScreenState();
}

class _BleTestScreenState extends State<BleTestScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isScanning = false;
  bool _isConnected = false;
  String _status = 'Not connected';
  String _lastSent = '';
  final List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  int _cwSpeed = 100;

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  Future<void> _initBle() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults.clear();
        _scanResults.addAll(results);
      });
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      _showSnackBar('Scan error: $e', Colors.red);
    }

    setState(() {
      _isScanning = false;
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _status = 'Connecting...';
    });

    try {
      await device.connect(timeout: const Duration(seconds: 10));

      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _writeCharacteristic = char;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _status = 'Connected to ${device.platformName}';
        if (_writeCharacteristic != null) {
          _status += '\nWrite characteristic found';
        } else {
          _status += '\nNo write characteristic found!';
        }
      });

      _showSnackBar('Connected to ${device.platformName}', Colors.green);
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
        _isConnected = false;
      });
      _showSnackBar('Connection failed: $e', Colors.red);
    }
  }

  Future<void> _disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      // Ignore
    }
    setState(() {
      _connectedDevice = null;
      _writeCharacteristic = null;
      _isConnected = false;
      _status = 'Disconnected';
    });
  }

  Future<void> _sendMorseCode(String text) async {
    if (!_isConnected || _writeCharacteristic == null) {
      _showSnackBar('Not connected or no write characteristic', Colors.orange);
      return;
    }

    try {
      final morse = Morse(text, message: text);
      final encoded = morse.encode(text);
      final speed = (_cwSpeed + 15).toString();
      final data = '${encoded}_$speed#';

      setState(() {
        _lastSent = 'Text: $text\nMorse: $data';
      });

      final bytes = utf8.encode(data);

      if (_writeCharacteristic!.properties.write) {
        await _writeCharacteristic!.write(bytes, withoutResponse: false);
      } else {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      }

      _showSnackBar('Sent: $text', Colors.green);
    } catch (e) {
      _showSnackBar('Send error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Listen to scan results and update dialog
            final scanSub = FlutterBluePlus.scanResults.listen((results) {
              setDialogState(() {
                _scanResults.clear();
                _scanResults.addAll(results);
              });
            });

            final scanningSub = FlutterBluePlus.isScanning.listen((scanning) {
              setDialogState(() {
                _isScanning = scanning;
              });
            });

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('BLE Devices'),
                  if (_isScanning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_isScanning) {
                          FlutterBluePlus.stopScan();
                        } else {
                          _scanResults.clear();
                          setDialogState(() {});
                          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
                        }
                      },
                      icon: Icon(_isScanning ? Icons.stop : Icons.search),
                      label: Text(_isScanning ? 'Stop' : 'Scan'),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Expanded(
                      child: _scanResults.isEmpty
                          ? const Center(child: Text('No devices found\nTap Scan to search'))
                          : ListView.builder(
                              itemCount: _scanResults.length,
                              itemBuilder: (context, index) {
                                final result = _scanResults[index];
                                final name = result.device.platformName.isNotEmpty
                                    ? result.device.platformName
                                    : 'Unknown';
                                return ListTile(
                                  title: Text(name),
                                  subtitle: Text(result.device.remoteId.str),
                                  trailing: Text('${result.rssi} dBm'),
                                  onTap: () {
                                    scanSub.cancel();
                                    scanningSub.cancel();
                                    FlutterBluePlus.stopScan();
                                    Navigator.pop(context);
                                    _connect(result.device);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    scanSub.cancel();
                    scanningSub.cancel();
                    FlutterBluePlus.stopScan();
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Morse Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: _isConnected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? 'Connected' : 'Not Connected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeviceDialog,
                    icon: const Icon(Icons.search),
                    label: const Text('Find Devices'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnect : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CW Speed: $_cwSpeed WPM'),
                    Slider(
                      value: _cwSpeed.toDouble(),
                      min: 50,
                      max: 150,
                      divisions: 20,
                      label: '$_cwSpeed WPM',
                      onChanged: (value) {
                        setState(() {
                          _cwSpeed = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 80,
              child: ElevatedButton.icon(
                onPressed: _isConnected ? () => _sendMorseCode('CQ CQ CQ') : null,
                icon: const Icon(Icons.send, size: 32),
                label: const Text(
                  'Send Morse Code\n"CQ CQ CQ"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? () => _sendMorseCode('TEST') : null,
                    child: const Text('Send TEST'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? () => _sendMorseCode('73') : null,
                    child: const Text('Send 73'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_lastSent.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Sent:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_lastSent, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
