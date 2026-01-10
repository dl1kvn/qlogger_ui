import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bluetooth_controller.dart';
import '../services/ble/ble_device.dart';

class BluetoothDialog extends StatelessWidget {
  final BluetoothController bluetoothController =
      Get.find<BluetoothController>();

  BluetoothDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bluetooth BLE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            // Connected device info
            Obx(() => bluetoothController.isConnected.value
                ? Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth_connected, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connected: ${bluetoothController.deviceName.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox()),

            const Divider(),

            // Device List
            SizedBox(
              height: 300,
              child: Obx(() {
                final results = bluetoothController.scanResults.toList();

                if (results.isEmpty) {
                  return Center(
                    child: bluetoothController.isScanning.value
                        ? const CircularProgressIndicator()
                        : const Text('No devices found\nTap Scan to search'),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    BleDevice device = results[index];

                    return ListTile(
                      title: Text(
                        device.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(device.id),
                      onTap: () async {
                        bluetoothController.stopScan();
                        await bluetoothController.connect(device);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Scan Button
                Obx(
                  () => ElevatedButton.icon(
                    icon: Icon(bluetoothController.isScanning.value
                        ? Icons.stop
                        : Icons.bluetooth_searching),
                    label: Text(bluetoothController.isScanning.value
                        ? 'Stop Scan'
                        : 'Start Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bluetoothController.isScanning.value
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () => bluetoothController.isScanning.value
                        ? bluetoothController.stopScan()
                        : bluetoothController.startScan(),
                  ),
                ),

                // Disconnect Button
                Obx(
                  () => bluetoothController.isConnected.value
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => bluetoothController.disconnect(),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
