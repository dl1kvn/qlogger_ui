import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../controllers/bluetooth_controller.dart';
import '../ui/componends/qso_form.dart';
import '../ui/theme/tokens.dart';
import '../ui/theme/text_styles.dart';
import '../widgets/bluetooth_dialog.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(QsoFormController());
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 22,
        title: const Text('qlogger'),
        titleTextStyle: AppBarStyles.title,
        actions: [
          // Bluetooth status icon
          Obx(() => GestureDetector(
            onTap: () => Get.dialog(BluetoothDialog()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                btController.isConnected.value
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                color: btController.isConnected.value
                    ? Colors.green
                    : Colors.grey,
                size: 18,
              ),
            ),
          )),
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                c.currentUtcTime.value,
                style: AppBarStyles.title,
              ),
            ),
          )),
        ],
      ),
      body: Padding(padding: Insets.page, child: const QsoForm()),
    );
  }
}
