import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'controllers/database_controller.dart';
import 'controllers/bluetooth_controller.dart';
import 'controllers/theme_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(DatabaseController(), permanent: true);
    Get.put(BluetoothController(), permanent: true);
  }
}

class QloggerApp extends StatelessWidget {
  const QloggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ThemeController early before bindings
    final themeController = Get.put(ThemeController(), permanent: true);
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      initialBinding: AppBindings(),
      home: const SplashScreen(),
    ));
  }
}
