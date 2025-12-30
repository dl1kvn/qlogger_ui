import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../ui/componends/qso_form.dart';
import '../ui/theme/tokens.dart';
import '../ui/theme/text_styles.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(QsoFormController());
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 22,
        title: const Text('qlogger'),
        titleTextStyle: AppBarStyles.title,
        actions: [
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
