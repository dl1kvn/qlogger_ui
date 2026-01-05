import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../ui/theme/color_scheme.dart';
import 'start_screen.dart';
import 'log_entry_screen.dart';
import 'setup_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static final List<Widget> _screens = const [
    StartScreen(),
    LogEntryScreen(),
    SetupScreen(),
  ];

  Future<bool> _showExitConfirmation() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Exit App', style: TextStyle(fontSize: 16)),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Obx(
      () {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final currentIndex = controller.currentIndex.value;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (currentIndex != 0) {
              // Not on start page - go to start page
              controller.changePage(0);
            } else {
              // On start page - show exit confirmation
              final shouldExit = await _showExitConfirmation();
              if (shouldExit) {
                SystemNavigator.pop();
              }
            }
          },
          child: Column(
            children: [
              Expanded(child: _screens[currentIndex]),
              BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: controller.changePage,
                backgroundColor: isDark ? Colors.grey.shade900 : AppColors.surfaceLight,
                selectedItemColor: Colors.red,
                selectedFontSize: 0,
                unselectedFontSize: 0,
                iconSize: 22,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_arrow_outlined),
                    activeIcon: Icon(Icons.play_arrow),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_outlined),
                    activeIcon: Icon(Icons.list_alt),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: '',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
