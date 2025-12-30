import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Obx(
      () => Column(
        children: [
          Expanded(child: _screens[controller.currentIndex.value]),
          BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            backgroundColor: AppColors.surfaceLight,
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
  }
}
