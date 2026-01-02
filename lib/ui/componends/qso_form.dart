import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/qso_form_controller.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/bluetooth_controller.dart';
import '../../screens/my_callsigns_screen.dart';
import '../theme/text_styles.dart';
import '../theme/paddings.dart';
import '../theme/input_decorations.dart';
import '../theme/color_scheme.dart';
import 'labeled_checkbox.dart';
import 'custom_keyboard.dart';

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
        'label': 'CQ',
        'color': Colors.green,
        'onPressed': c.sendCq,
      },
      'MY': {
        'label': 'MY',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
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
                      final activations = dbController.activationList;
                      return DropdownButtonFormField<int?>(
                        value: c.selectedActivationId.value,
                        decoration: InputStyles.dropdown(''),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('no activation'),
                          ),
                          ...activations.map((a) {
                            return DropdownMenuItem<int?>(
                              value: a.id,
                              child: Text(
                                '${a.type.toUpperCase()} ${a.reference}',
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
          Container(
            width: double.infinity,
            color: AppColors.surfaceLight,
            margin: P.field,
            padding: P.fieldBig,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: c.callsignController,
              builder: (context, callsignValue, child) =>
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: c.rstOutController,
                    builder: (context, rstValue, child) =>
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: c.xtra2Controller,
                          builder: (context, countValue, child) =>
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: c.cwPreController,
                                builder: (context, preValue, child) =>
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: c.cwPostController,
                                      builder: (context, postValue, child) => Obx(() {
                                        final activationId =
                                            c.selectedActivationId.value;
                                        String activationRef = '';
                                        if (activationId != null) {
                                          final dbController =
                                              Get.find<DatabaseController>();
                                          final activation = dbController
                                              .activationList
                                              .firstWhereOrNull(
                                                (a) => a.id == activationId,
                                              );
                                          if (activation != null) {
                                            activationRef =
                                                ' ${activation.reference.replaceAll('-', '')}';
                                          }
                                        }
                                        String rstText = rstValue.text;
                                        if (c.nineIsN.value) {
                                          rstText = rstText.replaceAll(
                                            '9',
                                            'N',
                                          );
                                        }
                                        String countText = '';
                                        if (c.useCounter.value &&
                                            countValue.text.isNotEmpty) {
                                          String count = countValue.text;
                                          if (c.zeroIsT.value) {
                                            count = count.replaceAll('0', 'T');
                                          }
                                          countText = ' $count';
                                        }
                                        String preText =
                                            preValue.text.isNotEmpty
                                            ? '${preValue.text} '
                                            : '';
                                        String postText =
                                            postValue.text.isNotEmpty
                                            ? ' ${postValue.text}'
                                            : '';
                                        String bkText = c.sendBK.value
                                            ? ' BK'
                                            : '';
                                        return Text(
                                          '${callsignValue.text.toUpperCase()} $preText$rstText$countText$activationRef$postText$bkText'
                                              .trim(),
                                          style: FormStyles.info,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }),
                                    ),
                              ),
                        ),
                  ),
            ),
          ),
          SizedBox(height: P.lineSpacing),

          // Service indicators row (hidden in contest mode)
          Obx(() {
            // Trigger rebuild when callsign changes
            c.selectedMyCallsign.value;
            if (c.contestMode.value) return const SizedBox.shrink();
            return Container(
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    child: LabeledCheckbox(label: 'NR', value: c.useCounter),
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
          // CW Speed slider (only visible in CW mode, hidden in contest mode)
          Obx(() {
            if (c.selectedMode.value != 'CW') return const SizedBox.shrink();
            if (c.contestMode.value) return const SizedBox.shrink();
            final btController = Get.find<BluetoothController>();
            // Clamp speed to valid range and update if out of bounds
            if (btController.cwSpeed.value < 16 ||
                btController.cwSpeed.value > 36) {
              btController.cwSpeed.value = btController.cwSpeed.value.clamp(
                16,
                36,
              );
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
          Obx(
            () => c.selectedMode.value == 'CW' && !c.contestMode.value
                ? Column(
                    children: [
                      Container(
                        padding: P.fieldBig,
                        color: AppColors.surfaceLight,
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
                  )
                : const SizedBox.shrink(),
          ),
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
                              final call = value.text.trim().toUpperCase();
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
                      onTap: () => c.setActiveTextField(c.callsignController),
                      decoration: c.workedBefore.value
                          ? InputStyles.fieldFilled(
                              'Callsign',
                            ).copyWith(filled: true, fillColor: Colors.red)
                          : InputStyles.fieldFilled('Callsign'),
                      style: c.workedBefore.value
                          ? FormStyles.callsign(
                              width,
                            ).copyWith(color: Colors.white)
                          : FormStyles.callsign(width),
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
                  child: Obx(() => TextFormField(
                    controller: c.rstInController,
                    focusNode: c.rstInFocus,
                    keyboardType: TextInputType.number,
                    readOnly: c.useCustomKeyboard.value,
                    showCursor: true,
                    decoration: InputStyles.fieldTight('IN'),
                    style: FormStyles.rstIn(width),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onTap: () {
                      c.setActiveTextField(c.rstInController);
                      _selectRstText(c, c.rstInController);
                    },
                  )),
                ),
              ),
              // RST OUT
              Expanded(
                flex: 2,
                child: Padding(
                  padding: P.fieldTight,
                  child: Obx(() => TextFormField(
                    controller: c.rstOutController,
                    focusNode: c.rstOutFocus,
                    keyboardType: TextInputType.number,
                    readOnly: c.useCustomKeyboard.value,
                    showCursor: true,
                    decoration: InputStyles.fieldTight('OUT'),
                    style: FormStyles.rstOut(width),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onTap: () {
                      c.setActiveTextField(c.rstOutController);
                      _selectRstText(c, c.rstOutController);
                    },
                  )),
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
                  child: Obx(() => TextFormField(
                    controller: c.receivedInfoController,
                    focusNode: c.infoFocus,
                    readOnly: c.useCustomKeyboard.value,
                    showCursor: true,
                    decoration: InputStyles.field('NR / INFO'),
                    onTap: () => c.setActiveTextField(c.receivedInfoController),
                    onChanged: c.onInfoChanged,
                    onFieldSubmitted: (_) => c.submitQso(),
                  )),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: P.fieldTight,
                  child: Obx(() => TextFormField(
                    controller: c.xtra1Controller,
                    focusNode: c.xtra1Focus,
                    readOnly: c.useCustomKeyboard.value,
                    showCursor: true,
                    decoration: InputStyles.field('Xtra 1'),
                    onTap: () => c.setActiveTextField(c.xtra1Controller),
                    onChanged: c.onXtra1Changed,
                  )),
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
                                decoration: InputStyles.field('HHMM').copyWith(
                                  suffixIcon: GestureDetector(
                                    onTap: () => _showTimePicker(context, c),
                                    child: const Icon(
                                      Icons.access_time,
                                      size: 16,
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
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
                        return DropdownMenuItem(value: band, child: Text(band));
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
                        return DropdownMenuItem(value: mode, child: Text(mode));
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

            return Column(
              children: rows.map((row) {
                // Filter out buttons that shouldn't be shown
                final visibleButtons = row.where((buttonId) {
                  // CUSTOM only visible if cwCustomText is set
                  if (buttonId == 'CUSTOM' && c.cwCustomText.value.isEmpty) {
                    return false;
                  }
                  // CW-specific buttons only visible in CW mode with BT connected
                  if (['CQ', 'MY', 'CALL', 'RPT', 'CUSTOM', 'SEND'].contains(buttonId)) {
                    if (!isCwMode || !isConnected) return false;
                  }
                  return true;
                }).toList();

                if (visibleButtons.isEmpty) return const SizedBox.shrink();

                return Row(
                  children: visibleButtons.map((buttonId) {
                    return Expanded(
                      child: _buildButton(buttonId, c),
                    );
                  }).toList(),
                );
              }).toList(),
            );
          }),
          // Matching QSOs list - takes remaining space
          Expanded(
            child: Obx(() {
              if (c.matchingQsos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: P.lineSpacing),
                child: ListView.builder(
                  itemCount: c.matchingQsos.length,
                  itemBuilder: (context, index) {
                    final qso = c.matchingQsos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${qso.callsign}  ${qso.qsodate}  ${qso.qsotime}  ${qso.band}  ${qso.mymode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
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
        Obx(() => c.useCustomKeyboard.value
            ? const CustomKeyboard()
            : const SizedBox.shrink()),
      ],
    );
  }
}
