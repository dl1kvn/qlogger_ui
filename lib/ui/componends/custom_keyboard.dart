import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/qso_form_controller.dart';

class _KeyboardSettings {
  static final height = 34.0.obs;
  static final isDark = true.obs;

  static void load() {
    final storage = GetStorage();
    height.value = (storage.read<int>('keyboard_height') ?? 34).toDouble();
    isDark.value = storage.read<bool>('keyboard_dark') ?? true;
  }

  static void save(double h, bool dark) {
    final storage = GetStorage();
    storage.write('keyboard_height', h.round());
    storage.write('keyboard_dark', dark);
    height.value = h;
    isDark.value = dark;
  }
}

class CustomKeyboard extends StatelessWidget {
  const CustomKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<QsoFormController>();
    _KeyboardSettings.load();

    return Obx(() {
      final isGerman = c.useGermanKeyboard.value;
      final keyHeight = _KeyboardSettings.height.value;
      final isDark = _KeyboardSettings.isDark.value;
      final activeField = c.activeTextField.value;
      final isRstField = activeField == c.rstInController || activeField == c.rstOutController;

      // Colors based on theme
      final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
      final keyColor = isDark ? Colors.grey.shade800 : Colors.white;
      final specialColor = isDark ? Colors.blueGrey : Colors.blueGrey.shade200;
      final spaceColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      final textColor = isDark ? Colors.white : Colors.black;
      final disabledColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      final disabledTextColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

      // Layout: Letters A-Z, Numbers 0-9, special chars /, -, ?, backspace
      // German layout swaps Y and Z
      const row1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
      final row2 = [
        'Q', 'W', 'E', 'R', 'T',
        isGerman ? 'Z' : 'Y',
        'U', 'I', 'O', 'P',
      ];
      const row3 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '/'];
      final row4 = [
        isGerman ? 'Y' : 'Z',
        'X', 'C', 'V', 'B', 'N', 'M', '-', '?', '⚙',
      ];

      void showSettings() {
        var tempHeight = keyHeight;
        var tempDark = isDark;

        Get.dialog(
          StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Keyboard Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Height: '),
                      Expanded(
                        child: Slider(
                          value: tempHeight,
                          min: 30,
                          max: 55,
                          divisions: 25,
                          label: tempHeight.round().toString(),
                          onChanged: (v) => setState(() => tempHeight = v),
                        ),
                      ),
                      Text('${tempHeight.round()}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const Text('Design: '),
                      ChoiceChip(
                        label: const Text('Dark'),
                        selected: tempDark,
                        onSelected: (_) => setState(() => tempDark = true),
                      ),
                      ChoiceChip(
                        label: const Text('Light'),
                        selected: !tempDark,
                        onSelected: (_) => setState(() => tempDark = false),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    _KeyboardSettings.save(tempHeight, tempDark);
                    Get.back();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      }

      Widget buildKey(String key, {int flex = 1}) {
        final isBackspace = key == '⌫';
        final isSpace = key == ' ';
        final isEsc = key == 'ESC';
        final isSettings = key == '⚙';
        final isSpecial = ['/', '-', '?'].contains(key);
        final isNumber = RegExp(r'^[0-9]$').hasMatch(key);
        final isDisabled = isRstField && !isNumber && !isBackspace && !isEsc;

        return Expanded(
          flex: flex,
          child: Material(
              color: isDisabled
                  ? disabledColor
                  : isBackspace || isEsc
                      ? Colors.red.shade300
                      : isSpace || isSettings
                          ? spaceColor
                          : isSpecial
                              ? specialColor
                              : keyColor,
              borderRadius: BorderRadius.circular(2),
              child: InkWell(
                onTap: isDisabled
                    ? null
                    : () {
                        if (isBackspace) {
                          c.deleteCharacter();
                        } else if (isSettings) {
                          showSettings();
                        } else if (isEsc) {
                          c.clearForm();
                        } else {
                          c.insertCharacter(key);
                        }
                      },
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: keyHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 0.5),
                  ),
                  child: isSettings
                      ? Icon(Icons.settings, color: textColor, size: 18)
                      : Text(
                          isSpace ? 'SPACE' : key,
                          style: TextStyle(
                            color: isDisabled
                                ? disabledTextColor
                                : isBackspace || isEsc
                                    ? Colors.white
                                    : textColor,
                            fontSize: isBackspace ? 18 : isSpace || isEsc ? 12 : 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
        );
      }

      Widget buildRow(List<String> keys) {
        return Row(children: keys.map((k) => buildKey(k)).toList());
      }

      return Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildRow(row1),
            buildRow(row2),
            buildRow(row3),
            buildRow(row4),
            Row(
              children: [
                buildKey('ESC'),
                buildKey(' ', flex: 3),
                buildKey('⌫'),
              ],
            ),
          ],
        ),
      );
    });
  }
}
