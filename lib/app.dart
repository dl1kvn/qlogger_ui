import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ui/theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'controllers/database_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(DatabaseController(), permanent: true);
  }
}

class QloggerApp extends StatelessWidget {
  const QloggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: AppBindings(),
      home: const MainShell(),
    );
  }
}
