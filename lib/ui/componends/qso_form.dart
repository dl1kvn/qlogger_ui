import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/qso_form_controller.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../screens/my_callsigns_screen.dart';
import '../../data/models/activation_model.dart';
import '../theme/text_styles.dart';
import '../theme/paddings.dart';
import '../theme/input_decorations.dart';
import '../theme/color_scheme.dart';
import 'labeled_checkbox.dart';
import 'custom_keyboard.dart';

// Info line color settings with persistence
final _storage = GetStorage();
final _infoLineBgColor = (_storage.read<int>('info_line_bg') ?? 0xFFFFE0B2).obs;
final _infoLineTextColor =
    (_storage.read<int>('info_line_text') ?? 0xFF000000).obs;
final _showRefPrefix = (_storage.read<bool>('show_ref_prefix') ?? false).obs;

void _showInfoLineSettings(BuildContext context) {
  final bgColors = [
    0xFFFFE0B2, // Light Orange
    0xFFFFCDD2, // Light Red
    0xFFC8E6C9, // Light Green
    0xFFBBDEFB, // Light Blue
    0xFFE1BEE7, // Light Purple
    0xFFFFF9C4, // Light Yellow
    0xFFFFFFFF, // White
    0xFF424242, // Dark Grey
  ];
  final textColors = [
    0xFF000000, // Black
    0xFFFFFFFF, // White
    0xFF1565C0, // Blue
    0xFFC62828, // Red
    0xFF2E7D32, // Green
  ];

  Get.dialog(
    AlertDialog(
      title: const Text('Info Line Setup', style: TextStyle(fontSize: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Background', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: bgColors.map((color) {
              return Obx(
                () => GestureDetector(
                  onTap: () {
                    _infoLineBgColor.value = color;
                    _storage.write('info_line_bg', color);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(color),
                      border: Border.all(
                        color: _infoLineBgColor.value == color
                            ? Colors.blue
                            : Colors.grey,
                        width: _infoLineBgColor.value == color ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Text', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: textColors.map((color) {
              return Obx(
                () => GestureDetector(
                  onTap: () {
                    _infoLineTextColor.value = color;
                    _storage.write('info_line_text', color);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(color),
                      border: Border.all(
                        color: _infoLineTextColor.value == color
                            ? Colors.blue
                            : Colors.grey,
                        width: _infoLineTextColor.value == color ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Obx(
            () => GestureDetector(
              onTap: () {
                _showRefPrefix.value = !_showRefPrefix.value;
                _storage.write('show_ref_prefix', _showRefPrefix.value);
              },
              child: Row(
                children: [
                  Icon(
                    _showRefPrefix.value
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'cw - send activation type \n eg 599 IOTA EU123',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('OK')),
      ],
    ),
  );
}

class QsoForm extends StatelessWidget {
  const QsoForm({super.key});

  Widget _buildServiceIndicator(
    String label,
    bool active,
    RxBool flashTrigger,
  ) {
    return Obx(() {
      final isFlashing = flashTrigger.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isFlashing ? 1.5 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isFlashing
                    ? Colors.green.shade300
                    : (active ? Colors.green : Colors.grey.shade400),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStatusIndicator(String label, bool active) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: active ? Colors.green : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildButton(String buttonId, QsoFormController c) {
    final buttonConfig = {
      'CQ': {
        'label': c.cwCqText.value.isEmpty
            ? 'CQ'
            : c.cwCqText.value.length > 6
            ? '${c.cwCqText.value.substring(0, 6)}…'
            : c.cwCqText.value,
        'color': Colors.green,
        'onPressed': c.sendCq,
      },
      'MY': {
        'label': c.selectedMyCallsign.value ?? 'MY',
        'color': Colors.grey,
        'onPressed': c.sendMyCall,
      },
      'CALL': {
        'label': 'CALL?',
        'color': Colors.blueGrey,
        'onPressed': c.sendHisCall,
      },
      'RPT': {
        'label': 'RPT#',
        'color': Colors.cyan,
        'onPressed': c.sendRprtOnly,
      },
      'CUSTOM': {
        'label': c.cwCustomText.value.length > 6
            ? '${c.cwCustomText.value.substring(0, 6)}…'
            : c.cwCustomText.value,
        'color': Colors.purple,
        'onPressed': c.sendCwCustomText,
      },
      'SEND': {
        'label': 'SEND',
        'color': Colors.deepOrangeAccent,
        'onPressed': c.sendCallPlusRprt,
      },
      'CLR': {
        'label': 'CLR',
        'color': AppColors.btnClear,
        'onPressed': c.clearForm,
      },
      'SAVE': {
        'label': 'SAVE',
        'color': AppColors.btnLog,
        'onPressed': c.submitQso,
      },
    };

    final config = buttonConfig[buttonId];
    if (config == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: config['onPressed'] as VoidCallback,
      style: ElevatedButton.styleFrom(
        backgroundColor: config['color'] as Color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: Text(
        config['label'] as String,
        style: ButtonStyles.button,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    QsoFormController c,
  ) async {
    // Parse current date from controller or use today
    DateTime initialDate = DateTime.now().toUtc();
    if (c.dateController.text.length == 8) {
      try {
        // Format: YYYYMMDD
        final year = int.parse(c.dateController.text.substring(0, 4));
        final month = int.parse(c.dateController.text.substring(4, 6));
        final day = int.parse(c.dateController.text.substring(6, 8));
        initialDate = DateTime(year, month, day);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted =
          '${picked.year}${picked.month.toString().padLeft(2, '0')}${picked.day.toString().padLeft(2, '0')}';
      c.dateController.text = formatted;
    }
  }

  Future<void> _showTimePicker(
    BuildContext context,
    QsoFormController c,
  ) async {
    // Parse current time from controller or use now
    TimeOfDay initialTime = TimeOfDay.now();
    if (c.timeController.text.length == 4) {
      try {
        final hour = int.parse(c.timeController.text.substring(0, 2));
        final minute = int.parse(c.timeController.text.substring(2, 4));
        initialTime = TimeOfDay(hour: hour, minute: minute);
      } catch (_) {}
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'USE UTC!',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}${picked.minute.toString().padLeft(2, '0')}';
      c.timeController.text = formatted;
    }
  }

  void _selectRstText(QsoFormController c, TextEditingController controller) {
    // Delay to let the field gain focus first
    Future.delayed(const Duration(milliseconds: 50), () {
      final text = controller.text;
      if (c.singleRst.value && text.length >= 2) {
        // Select only the second character (signal strength)
        controller.selection = TextSelection(baseOffset: 1, extentOffset: 2);
      } else {
        // Select all text
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(QsoFormController());
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Expanded(
          child: Form(
            key: c.formKey,
            child: Column(
              children: [
                // Top row: Bluetooth, My Callsign, Status
                Container(
                  color: AppColors.surfaceLight,
                  child: Row(
                    children: [
                      // My Callsign dropdown
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: P.field,
                          child: Obx(
                            () => c.myCallsigns.isEmpty
                                ? TextButton(
                                    onPressed: () =>
                                        Get.to(() => const MyCallsignsScreen()),
                                    child: const Text('add call'),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: c.selectedMyCallsign.value,
                                    decoration: InputStyles.dropdown(''),
                                    isExpanded: true,
                                    items: c.myCallsigns.map((call) {
                                      return DropdownMenuItem(
                                        value: call,
                                        child: Text(call),
                                      );
                                    }).toList(),
                                    onChanged: c.onMyCallsignChanged,
                                  ),
                          ),
                        ),
                      ),
                      // Activation dropdown
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: P.field,
                          child: Obx(() {
                            final dbController = Get.find<DatabaseController>();
                            final activations = dbController.activationList
                                .where((a) => a.showInDropdown)
                                .toList();
                            return DropdownButtonFormField<int?>(
                              value: c.selectedActivationId.value,
                              decoration: InputStyles.dropdown(''),
                              isExpanded: true,
                              itemHeight: 56,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('no activation'),
                                ),
                                ...activations.map((a) {
                                  return DropdownMenuItem<int?>(
                                    value: a.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          ActivationModel.getIcon(a.type),
                                          size: 16,
                                          color: ActivationModel.getColor(
                                            a.type,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                a.reference,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (a.title.isNotEmpty)
                                                Text(
                                                  a.title,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (a.imagePath != null) ...[
                                          const SizedBox(width: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            child: Image.file(
                                              File(a.imagePath!),
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                c.selectedActivationId.value = value;
                              },
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: P.lineSpacing),
                // Status text
                Obx(() {
                  final bgColor = Color(_infoLineBgColor.value);
                  final textColor = Color(_infoLineTextColor.value);
                  return Container(
                    width: double.infinity,
                    color: bgColor,
                    margin: P.field,
                    padding: P.fieldBig,
                    child: Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: c.callsignController,
                            builder: (context, callsignValue, child) =>
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: c.rstOutController,
                                  builder: (context, rstValue, child) =>
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: c.xtra2Controller,
                                        builder: (context, countValue, child) =>
                                            ValueListenableBuilder<
                                              TextEditingValue
                                            >(
                                              valueListenable:
                                                  c.cwPreController,
                                              builder: (context, preValue, child) =>
                                                  ValueListenableBuilder<
                                                    TextEditingValue
                                                  >(
                                                    valueListenable:
                                                        c.cwPostController,
                                                    builder: (context, postValue, child) => Obx(() {
                                                      final activationId = c
                                                          .selectedActivationId
                                                          .value;
                                                      String activationRef = '';
                                                      if (activationId !=
                                                          null) {
                                                        final dbController =
                                                            Get.find<
                                                              DatabaseController
                                                            >();
                                                        final activation =
                                                            dbController
                                                                .activationList
                                                                .firstWhereOrNull(
                                                                  (a) =>
                                                                      a.id ==
                                                                      activationId,
                                                                );
                                                        if (activation !=
                                                            null) {
                                                          if (_showRefPrefix
                                                              .value) {
                                                            activationRef =
                                                                ' ${activation.type.toUpperCase()} ${activation.reference.replaceAll('-', '')}';
                                                          } else {
                                                            activationRef =
                                                                ' ${activation.reference.replaceAll('-', '')}';
                                                          }
                                                        }
                                                      }
                                                      String rstText =
                                                          rstValue.text;
                                                      if (c.nineIsN.value) {
                                                        rstText = rstText
                                                            .replaceAll(
                                                              '9',
                                                              'N',
                                                            );
                                                      }
                                                      String countText = '';
                                                      if (c.useCounter.value &&
                                                          countValue
                                                              .text
                                                              .isNotEmpty) {
                                                        String count =
                                                            countValue.text;
                                                        if (c.zeroIsT.value) {
                                                          count = count
                                                              .replaceAll(
                                                                '0',
                                                                'T',
                                                              );
                                                        }
                                                        countText = ' $count';
                                                      }
                                                      String preText =
                                                          preValue
                                                              .text
                                                              .isNotEmpty
                                                          ? '${preValue.text} '
                                                          : '';
                                                      String postText =
                                                          postValue
                                                              .text
                                                              .isNotEmpty
                                                          ? ' ${postValue.text}'
                                                          : '';
                                                      String bkText =
                                                          c.sendBK.value
                                                          ? ' BK'
                                                          : '';
                                                      return Text(
                                                        '${callsignValue.text.toUpperCase()} $preText$rstText$countText$activationRef$postText$bkText'
                                                            .trim(),
                                                        style: FormStyles.info
                                                            .copyWith(
                                                              color: textColor,
                                                            ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      );
                                                    }),
                                                  ),
                                            ),
                                      ),
                                ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showInfoLineSettings(context),
                          child: Icon(
                            Icons.settings,
                            size: 18,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: P.lineSpacing),

                // Service indicators row (hidden in contest mode)
                Obx(() {
                  // Trigger rebuild when callsign changes
                  c.selectedMyCallsign.value;
                  if (c.contestMode.value) return const SizedBox.shrink();
                  final isDark = Get.find<ThemeController>().isDarkMode.value;
                  return Container(
                    color: isDark ? Colors.black : AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildServiceIndicator(
                          'Clublog',
                          c.useClublog,
                          c.clublogFlash,
                        ),
                        const SizedBox(width: 2),
                        _buildServiceIndicator('eQSL', c.useEqsl, c.eqslFlash),
                        const SizedBox(width: 2),
                        _buildServiceIndicator('LoTW', c.useLotw, c.lotwFlash),
                        const SizedBox(width: 2),
                        const Text(
                          '|',
                          style: TextStyle(fontSize: 8, color: Colors.red),
                        ),
                        const SizedBox(width: 2),
                        _buildStatusIndicator('SPC', c.useSpacebarToggle),
                        const SizedBox(width: 2),
                        _buildStatusIndicator('2nd', c.toggleSecondField),
                        const SizedBox(width: 2),
                        const Text(
                          '|',
                          style: TextStyle(fontSize: 8, color: Colors.red),
                        ),
                        const SizedBox(width: 2),
                        // Counter checkbox
                        Padding(
                          padding: P.field,
                          child: LabeledCheckbox(
                            label: 'NR',
                            value: c.useCounter,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          '|',
                          style: TextStyle(fontSize: 8, color: Colors.red),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: TextFormField(
                            controller: c.locatorController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              isDense: true,
                              suffixIcon: Obx(
                                () => GestureDetector(
                                  onTap: c.isGettingLocation.value
                                      ? null
                                      : c.getLocator,
                                  child: c.isGettingLocation.value
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.my_location, size: 18),
                                ),
                              ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: P.lineSpacing),
                // CW Speed slider (only visible in CW mode, BT connected, hidden in contest mode)
                Obx(() {
                  final btController = Get.find<BluetoothController>();
                  if (c.selectedMode.value != 'CW')
                    return const SizedBox.shrink();
                  if (!btController.isConnected.value)
                    return const SizedBox.shrink();
                  if (c.contestMode.value) return const SizedBox.shrink();
                  // Clamp speed to valid range and update if out of bounds
                  if (btController.cwSpeed.value < 16 ||
                      btController.cwSpeed.value > 36) {
                    btController.cwSpeed.value = btController.cwSpeed.value
                        .clamp(16, 36);
                  }
                  return Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.surfaceLight,
                    child: Row(
                      children: [
                        Obx(
                          () => Text(
                            '${btController.cwSpeed.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(
                            () => SliderTheme(
                              data: SliderTheme.of(Get.context!).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value: btController.cwSpeed.value.toDouble(),
                                min: 16,
                                max: 36,
                                divisions: 20,
                                onChanged: (value) {
                                  btController.cwSpeed.value = value.round();
                                  // Send speed to Arduino if connected
                                  if (btController.isConnected.value) {
                                    btController.sendSpeedChange();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: P.lineSpacing),
                // CW Checkbox row (only visible in CW mode, hidden in contest mode)
                Obx(() {
                  if (c.selectedMode.value != 'CW' || c.contestMode.value) {
                    return const SizedBox.shrink();
                  }
                  final isDark = Get.find<ThemeController>().isDarkMode.value;
                  return Column(
                    children: [
                      Container(
                        padding: P.fieldBig,
                        color: isDark ? Colors.black : AppColors.surfaceLight,
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxRow(
                                checkboxes: [
                                  LabeledCheckbox(
                                    label: '0/t',
                                    value: c.zeroIsT,
                                  ),
                                  LabeledCheckbox(
                                    label: '9/n',
                                    value: c.nineIsN,
                                  ),
                                  LabeledCheckbox(label: 'K', value: c.sendK),
                                  LabeledCheckbox(label: 'BK', value: c.sendBK),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 46,
                              height: 28,
                              child: TextFormField(
                                controller: c.cwPreController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  labelText: 'pre',
                                  labelStyle: TextStyle(fontSize: 9),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => c.saveCwPre(v.toUpperCase()),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 46,
                              height: 28,
                              child: TextFormField(
                                controller: c.cwPostController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  labelText: 'post',
                                  labelStyle: TextStyle(fontSize: 9),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => c.saveCwPost(v.toUpperCase()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: P.lineSpacing),
                    ],
                  );
                }),
                // Row 1: Icon, Callsign, RST IN, RST OUT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QRZ Icon - opens qrz.com when callsign is valid
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: c.callsignController,
                      builder: (context, value, child) {
                        // Callsign regex: at least one letter, one digit, and one letter
                        final callsignRegex = RegExp(
                          r'^[A-Z0-9]{1,3}[0-9][A-Z0-9]*[A-Z]$',
                          caseSensitive: false,
                        );
                        final isValidCallsign = callsignRegex.hasMatch(
                          value.text.trim(),
                        );
                        return Padding(
                          padding: P.icon,
                          child: GestureDetector(
                            onTap: isValidCallsign
                                ? () async {
                                    final call = value.text
                                        .trim()
                                        .toUpperCase();
                                    final url = Uri(
                                      scheme: 'https',
                                      host: 'www.qrz.com',
                                      path: '/db/$call',
                                    );
                                    try {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(e.toString());
                                    }
                                  }
                                : null,
                            child: Icon(
                              Icons.emoji_people,
                              size: 28,
                              color: isValidCallsign
                                  ? Colors.blueAccent
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                    // Callsign
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: P.fieldTight,
                        child: Obx(
                          () => TextFormField(
                            controller: c.callsignController,
                            focusNode: c.callsignFocus,
                            textCapitalization: TextCapitalization.characters,
                            readOnly: c.useCustomKeyboard.value,
                            showCursor: true,
                            onTap: () =>
                                c.setActiveTextField(c.callsignController),
                            decoration: c.workedBefore.value
                                ? InputStyles.fieldFilled('Callsign').copyWith(
                                    filled: true,
                                    fillColor: Colors.red,
                                  )
                                : InputStyles.fieldFilled('Callsign').copyWith(
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                            style: c.workedBefore.value
                                ? FormStyles.callsign(
                                    width,
                                  ).copyWith(color: Colors.white)
                                : FormStyles.callsign(
                                    width,
                                  ).copyWith(color: Colors.black),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                            onChanged: c.onCallsignChanged,
                            onFieldSubmitted: (_) => c.submitQso(),
                          ),
                        ),
                      ),
                    ),
                    // RST IN
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: P.fieldTight,
                        child: Obx(
                          () => TextFormField(
                            controller: c.rstInController,
                            focusNode: c.rstInFocus,
                            keyboardType: TextInputType.number,
                            readOnly: c.useCustomKeyboard.value,
                            showCursor: true,
                            decoration: InputStyles.fieldTight('IN'),
                            style: FormStyles.rstIn(width),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onTap: () {
                              c.setActiveTextField(c.rstInController);
                              _selectRstText(c, c.rstInController);
                            },
                          ),
                        ),
                      ),
                    ),
                    // RST OUT
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: P.fieldTight,
                        child: Obx(
                          () => TextFormField(
                            controller: c.rstOutController,
                            focusNode: c.rstOutFocus,
                            keyboardType: TextInputType.number,
                            readOnly: c.useCustomKeyboard.value,
                            showCursor: true,
                            decoration: InputStyles.fieldTight('OUT'),
                            style: FormStyles.rstOut(width),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onTap: () {
                              c.setActiveTextField(c.rstOutController);
                              _selectRstText(c, c.rstOutController);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: P.lineSpacing),
                // Row 2: Received Info, Xtra1, Xtra2
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: P.fieldTight,
                        child: Obx(
                          () => TextFormField(
                            controller: c.receivedInfoController,
                            focusNode: c.infoFocus,
                            readOnly: c.useCustomKeyboard.value,
                            showCursor: true,
                            decoration: InputStyles.field('NR / INFO'),
                            onTap: () =>
                                c.setActiveTextField(c.receivedInfoController),
                            onChanged: c.onInfoChanged,
                            onFieldSubmitted: (_) => c.submitQso(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: P.fieldTight,
                        child: Obx(
                          () => TextFormField(
                            controller: c.xtra1Controller,
                            focusNode: c.xtra1Focus,
                            readOnly: c.useCustomKeyboard.value,
                            showCursor: true,
                            decoration: InputStyles.field('Xtra 1'),
                            onTap: () =>
                                c.setActiveTextField(c.xtra1Controller),
                            onChanged: c.onXtra1Changed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Row 3: Date, Time (hidden when hideDateTime is true)
                Obx(
                  () => c.hideDateTime.value
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            SizedBox(height: P.lineSpacing),
                            Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: P.field,
                                    child: TextFormField(
                                      controller: c.dateController,
                                      decoration: InputStyles.field('YYYYMMDD')
                                          .copyWith(
                                            suffixIcon: GestureDetector(
                                              onTap: () =>
                                                  _showDatePicker(context, c),
                                              child: const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                              ),
                                            ),
                                            suffixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                          ),
                                      onTap: () => _showDatePicker(context, c),
                                      readOnly: true,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: P.field,
                                    child: TextFormField(
                                      controller: c.timeController,
                                      decoration: InputStyles.field('HHMM')
                                          .copyWith(
                                            suffixIcon: GestureDetector(
                                              onTap: () =>
                                                  _showTimePicker(context, c),
                                              child: const Icon(
                                                Icons.access_time,
                                                size: 16,
                                              ),
                                            ),
                                            suffixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                          ),
                                      onTap: () => _showTimePicker(context, c),
                                      readOnly: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                SizedBox(height: P.lineSpacing),
                // Row 4: Band, Mode dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: P.field,
                        child: Obx(() {
                          // Access selectedMyCallsign to rebuild when it changes
                          c.selectedMyCallsign.value;
                          final currentBands = c.bands;
                          final currentBand =
                              currentBands.contains(c.selectedBand.value)
                              ? c.selectedBand.value
                              : currentBands.first;
                          return DropdownButtonFormField<String>(
                            value: currentBand,
                            decoration: InputStyles.dropdown('Band'),
                            items: currentBands.map((band) {
                              return DropdownMenuItem(
                                value: band,
                                child: Text(band),
                              );
                            }).toList(),
                            onChanged: c.onBandChanged,
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: P.field,
                        child: Obx(() {
                          // Access selectedMyCallsign to rebuild when it changes
                          c.selectedMyCallsign.value;
                          final currentModes = c.modes;
                          final currentMode =
                              currentModes.contains(c.selectedMode.value)
                              ? c.selectedMode.value
                              : currentModes.first;
                          return DropdownButtonFormField<String>(
                            value: currentMode,
                            decoration: InputStyles.dropdown('Mode'),
                            items: currentModes.map((mode) {
                              return DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              );
                            }).toList(),
                            onChanged: c.onModeChanged,
                          );
                        }),
                      ),
                    ),
                    // Sat dropdown (only visible when showSatellite is enabled)
                    Obx(
                      () => c.showSatellite.value
                          ? Expanded(
                              child: Padding(
                                padding: P.field,
                                child: DropdownButtonFormField<String>(
                                  value: c.selectedSatellite.value,
                                  decoration: InputStyles.dropdown('Sat'),
                                  isExpanded: true,
                                  items: c.satellites.map((sat) {
                                    return DropdownMenuItem(
                                      value: sat,
                                      child: Text(
                                        sat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: c.onSatelliteChanged,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    // Count textbox (only visible when useCounter is enabled)
                    Obx(
                      () => c.useCounter.value
                          ? Padding(
                              padding: P.fieldTight,
                              child: SizedBox(
                                width: 60,
                                child: TextFormField(
                                  controller: c.xtra2Controller,
                                  decoration: InputStyles.dropdown('count'),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                SizedBox(height: P.lineSpacing),
                // Dynamic button rows based on saved layout
                Obx(() {
                  final btController = Get.find<BluetoothController>();
                  final isCwMode = c.selectedMode.value == 'CW';
                  final isConnected = btController.isConnected.value;
                  final rows = c.buttonLayoutRows.value;

                  // Check if button should be visible
                  bool isButtonVisible(String buttonId) {
                    if (buttonId == 'CUSTOM' && c.cwCustomText.value.isEmpty) {
                      return false;
                    }
                    if ([
                      'CQ',
                      'MY',
                      'CALL',
                      'RPT',
                      'CUSTOM',
                      'SEND',
                    ].contains(buttonId)) {
                      if (!isCwMode || !isConnected) return false;
                    }
                    return true;
                  }

                  return Column(
                    children: rows.asMap().entries.map((entry) {
                      final rowIndex = entry.key;
                      final row = entry.value;
                      if (row.isEmpty) return const SizedBox.shrink();

                      // Check if any button in this row is visible
                      final hasVisibleButton = row.any(
                        (buttonId) => isButtonVisible(buttonId),
                      );
                      if (!hasVisibleButton) return const SizedBox.shrink();

                      return Column(
                        children: [
                          if (rowIndex > 0 &&
                              rows
                                  .sublist(0, rowIndex)
                                  .any((r) => r.any((b) => isButtonVisible(b))))
                            const SizedBox(height: 2),
                          Row(
                            children: row.map((buttonId) {
                              if (!isButtonVisible(buttonId)) {
                                return const Expanded(child: SizedBox.shrink());
                              }
                              return Expanded(child: _buildButton(buttonId, c));
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }),
                // Matching QSOs list - takes remaining space
                Expanded(
                  child: Obx(() {
                    if (c.matchingQsos.isEmpty) return const SizedBox.shrink();
                    final currentCall = c.callsignController.text
                        .trim()
                        .toUpperCase();
                    final currentBand = c.selectedBand.value;
                    final currentMode = c.selectedMode.value;

                    // Sort: exact matches first
                    final sortedQsos = c.matchingQsos.toList()
                      ..sort((a, b) {
                        final aExact =
                            a.callsign.trim().toUpperCase() == currentCall &&
                            a.band == currentBand &&
                            a.mymode == currentMode;
                        final bExact =
                            b.callsign.trim().toUpperCase() == currentCall &&
                            b.band == currentBand &&
                            b.mymode == currentMode;
                        if (aExact && !bExact) return -1;
                        if (!aExact && bExact) return 1;
                        return 0;
                      });

                    final itemCount = sortedQsos.length;
                    final rowCount = (itemCount / 2).ceil();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ListView.builder(
                        itemCount: rowCount,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, rowIndex) {
                          return Row(
                            children: List.generate(2, (colIndex) {
                              final index = rowIndex * 2 + colIndex;
                              if (index >= itemCount)
                                return const Expanded(child: SizedBox());
                              final qso = sortedQsos[index];
                              final isExactMatch =
                                  currentCall.isNotEmpty &&
                                  qso.callsign.trim().toUpperCase() ==
                                      currentCall &&
                                  qso.band == currentBand &&
                                  qso.mymode == currentMode;
                              return Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isExactMatch ? Colors.red : null,
                                    border: Border(
                                      top: rowIndex == 0
                                          ? BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.5,
                                            )
                                          : BorderSide.none,
                                      bottom: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 0.5,
                                      ),
                                      left: colIndex == 0
                                          ? BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.5,
                                            )
                                          : BorderSide.none,
                                      right: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${qso.callsign} ${qso.qsodate} ${qso.band} ${qso.mymode}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isExactMatch ? Colors.white : null,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        // Custom keyboard at bottom
        Obx(
          () => c.useCustomKeyboard.value
              ? const CustomKeyboard()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
