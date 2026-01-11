import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/theme_controller.dart';
import '../ui/componends/qso_form.dart';
import '../ui/theme/tokens.dart';
import '../widgets/bluetooth_dialog.dart';
import 'simulation_setup_screen.dart';
import 'callsign_edit_screen.dart';

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
            offset: const Offset(-2, 0),
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

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final QsoFormController c;
  late final BluetoothController btController;
  late final ThemeController themeController;

  @override
  void initState() {
    super.initState();
    c = Get.put(QsoFormController());
    btController = Get.find<BluetoothController>();
    themeController = Get.find<ThemeController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCallsignPopupIfNeeded();
    });
  }

  void _showCallsignPopupIfNeeded() {
    if (c.myCallsigns.isEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('No Callsign Configured'),
          content: const Text(
            'You need to add your callsign to start logging QSOs.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Get.back();
                Get.to(() => const CallsignEditScreen());
              },
              child: const Text('Add Callsign'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconRow = PreferredSize(
      preferredSize: const Size.fromHeight(32),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
            // Serial number (NR) toggle
            Obx(
              () => _appBarIconButton(
                icon: Icons.tag,
                color: c.useCounter.value ? Colors.green : Colors.grey,
                onTap: c.toggleUseCounter,
              ),
            ),
            // Simulation mode toggle
            Obx(
              () => _appBarIconButton(
                icon: Icons.school,
                color: simulationActive.value ? Colors.green : Colors.grey,
                onTap: () {
                  if (simulationActive.value) {
                    // Stop simulation
                    simulationActive.value = false;
                    simulationPaused.value = false;
                  } else {
                    // Start simulation
                    simulationActive.value = true;
                    simulationPaused.value = true;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          toolbarHeight: 36,
          title: Row(
            children: [
              qloggerSpeedWordmark(fontSize: 18),
              const Spacer(),
              // Contest mode toggle icon
              _appBarIconButton(
                icon: Icons.compress,
                color: c.contestMode.value ? Colors.green : Colors.grey,
                onTap: c.toggleContestMode,
              ),
              const SizedBox(width: 4),
              // Custom keyboard toggle icon
              _appBarIconButton(
                icon: Icons.keyboard,
                color: c.useCustomKeyboard.value ? Colors.green : Colors.grey,
                onTap: c.toggleCustomKeyboard,
              ),
              const SizedBox(width: 4),
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
              const SizedBox(width: 8),
              // UTC Time
              Text(
                '${c.currentUtcTime.value} UTC',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              // Wifi indicator
              Icon(
                c.hasInternet.value ? Icons.wifi : Icons.wifi_off,
                size: 18,
                color: c.hasInternet.value ? Colors.green : Colors.red,
              ),
            ],
          ),
          bottom: c.contestMode.value ? null : iconRow,
        ),
        body: Padding(padding: Insets.page, child: const QsoForm()),
      ),
    );
  }
}
