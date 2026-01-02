import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../controllers/bluetooth_controller.dart';
import '../ui/componends/qso_form.dart';
import '../ui/theme/tokens.dart';
import '../ui/theme/text_styles.dart';
import '../widgets/bluetooth_dialog.dart';

Widget qloggerSpeedWordmark({double fontSize = 14, Color? color}) {
  return Builder(
    builder: (context) {
      final c =
          color ??
          Theme.of(context).appBarTheme.foregroundColor ??
          Colors.redAccent;

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Ghost 1 (weiter hinten)
          Transform.translate(
            offset: const Offset(-6, 0),
            child: Text(
              'qlogger',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: c.withOpacity(0.15),
              ),
            ),
          ),
          // Ghost 2 (näher dran)
          Transform.translate(
            offset: const Offset(-3, 0),
            child: Text(
              'qlogger',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: c.withOpacity(0.35),
              ),
            ),
          ),
          // Main text
          Text(
            'qlogger',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: c,
            ),
          ),
        ],
      );
    },
  );
}

Widget _appBarIconButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  double size = 20,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: size, color: color),
    ),
  );
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(QsoFormController());
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 36,
        title: qloggerSpeedWordmark(fontSize: 18),
        actions: [
          // Bluetooth status icon
          Obx(
            () => _appBarIconButton(
              icon: btController.isConnected.value
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
              color: btController.isConnected.value
                  ? Colors.green
                  : Colors.grey,
              onTap: () => Get.dialog(BluetoothDialog()),
            ),
          ),
          // Date/Time toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.access_time,
              color: c.hideDateTime.value ? Colors.red : Colors.green,
              onTap: c.toggleHideDateTime,
            ),
          ),
          // Satellite toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.satellite_alt,
              color: c.showSatellite.value ? Colors.green : Colors.grey,
              onTap: c.toggleShowSatellite,
            ),
          ),
          // Contest mode toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.emoji_events,
              color: c.contestMode.value ? Colors.green : Colors.grey,
              onTap: c.toggleContestMode,
            ),
          ),
          // Custom keyboard toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.keyboard,
              color: c.useCustomKeyboard.value ? Colors.green : Colors.grey,
              onTap: c.toggleCustomKeyboard,
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(left: 6, right: 12),
              child: Center(
                child: Text(c.currentUtcTime.value, style: AppBarStyles.title),
              ),
            ),
          ),
        ],
      ),
      body: Padding(padding: Insets.page, child: const QsoForm()),
    );
  }
}
