import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/theme_controller.dart';
import '../ui/componends/qso_form.dart';
import '../ui/theme/tokens.dart';
import '../widgets/bluetooth_dialog.dart';

Widget qloggerSpeedWordmark({double fontSize = 24, Color? color}) {
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
            offset: const Offset(-4, 0),
            child: Text(
              'q',
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
            offset: const Offset(-2, 0),
            child: Text(
              'q',
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
            'q',
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
    final themeController = Get.find<ThemeController>();

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
          // Contest mode toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.emoji_events,
              color: c.contestMode.value ? Colors.green : Colors.grey,
              onTap: c.toggleContestMode,
            ),
          ),
          // Serial number (NR) toggle
          Obx(
            () => _appBarIconButton(
              icon: Icons.tag,
              color: c.useCounter.value ? Colors.green : Colors.grey,
              onTap: c.toggleUseCounter,
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
          // Theme toggle icon
          Obx(
            () => _appBarIconButton(
              icon: themeController.isDarkMode.value
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.grey,
              onTap: themeController.toggleTheme,
            ),
          ),
          // Stay awake toggle icon
          Obx(
            () => _appBarIconButton(
              icon: Icons.coffee,
              color: c.stayAwake.value ? Colors.green : Colors.grey,
              onTap: c.toggleStayAwake,
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(left: 6, right: 4),
              child: Center(
                child: Text(
                  c.currentUtcTime.value,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                c.hasInternet.value ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: c.hasInternet.value ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: Padding(padding: Insets.page, child: const QsoForm()),
    );
  }
}
