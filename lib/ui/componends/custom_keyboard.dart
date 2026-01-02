import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/qso_form_controller.dart';

class CustomKeyboard extends StatelessWidget {
  const CustomKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<QsoFormController>();

    // Layout: Letters A-Z, Numbers 0-9, special chars /, -, ?, backspace
    const row1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    const row2 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row3 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '/'];
    const row4 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '-', '?', '⌫'];

    Widget buildKey(String key) {
      final isBackspace = key == '⌫';
      final isSpecial = ['/', '-', '?'].contains(key);

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: isBackspace
                ? Colors.red.shade400
                : isSpecial
                    ? Colors.blueGrey
                    : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () {
                if (isBackspace) {
                  c.deleteCharacter();
                } else {
                  c.insertCharacter(key);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                child: Text(
                  key,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isBackspace ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildRow(List<String> keys) {
      return Row(
        children: keys.map(buildKey).toList(),
      );
    }

    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildRow(row1),
          buildRow(row2),
          buildRow(row3),
          buildRow(row4),
        ],
      ),
    );
  }
}
