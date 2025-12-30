import 'package:get/get.dart';
import 'qso_form_controller.dart';

class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    final previousIndex = currentIndex.value;
    currentIndex.value = index;

    // When navigating to StartScreen (index 0), clear callsign and focus
    if (index == 0 && previousIndex != 0) {
      _focusStartScreen();
    }
  }

  void _focusStartScreen() {
    try {
      final qsoController = Get.find<QsoFormController>();
      qsoController.callsignController.clear();
      qsoController.callsignFocus.requestFocus();
    } catch (_) {
      // Controller not yet initialized
    }
  }
}
