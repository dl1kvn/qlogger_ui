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
import 'dart:math' show Random;
import '../../screens/simulation_setup_screen.dart'
    show
        simulationActive,
        simulationPaused,
        simulationMinWpm,
        simulationMaxWpm,
        simulationCqWpm,
        simulationGeneratedCallsign,
        simulationGeneratedNumber,
        simulationGeneratedCode,
        simulationAwaitingResponse,
        simulationResultList,
        simulationSaveCount,
        SimulationResult;
import '../../services/morse_audio_service.dart';
import '../../data/models/activation_model.dart';
import '../theme/text_styles.dart';
import '../theme/paddings.dart';
import '../theme/input_decorations.dart';
import '../theme/color_scheme.dart';
import 'labeled_checkbox.dart';
import 'custom_keyboard.dart';

// Uppercase text formatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// Info line color settings with persistence
final _storage = GetStorage();
// Send locator toggle
final _sendLocator = (_storage.read<bool>('send_locator') ?? false).obs;
final _infoLineBgColor = (_storage.read<int>('info_line_bg') ?? 0xFFFFE0B2).obs;
final _infoLineTextColor =
    (_storage.read<int>('info_line_text') ?? 0xFF000000).obs;
final _showRefPrefix = (_storage.read<bool>('show_ref_prefix') ?? false).obs;

void _showInfoLineSettings(BuildContext context) {
  final isDark = Get.find<ThemeController>().isDarkMode.value;
  final textColor = isDark ? Colors.white : Colors.black87;
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
          Text('Background', style: TextStyle(fontSize: 12, color: textColor)),
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
          Text('Text', style: TextStyle(fontSize: 12, color: textColor)),
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
          const Divider(),
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
                    color: textColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: textColor),
                        children: const [
                          TextSpan(
                            text: 'cw - send activation type \n eg 599 ',
                          ),
                          TextSpan(
                            text: 'IOTA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          TextSpan(text: ' EU123'),
                        ],
                      ),
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

// External keyboard mapping storage
final _extKeyStorage = GetStorage();

String _keyEventToString(KeyEvent event) {
  final List<String> parts = [];
  if (HardwareKeyboard.instance.isControlPressed) parts.add('Ctrl');
  if (HardwareKeyboard.instance.isAltPressed) parts.add('Alt');
  if (HardwareKeyboard.instance.isShiftPressed) parts.add('Shift');
  if (HardwareKeyboard.instance.isMetaPressed) parts.add('Meta');

  final key = event.logicalKey;
  String keyLabel = key.keyLabel;
  if (keyLabel.isEmpty) keyLabel = key.debugName ?? 'Unknown';

  // Don't add modifier keys as main key
  if (key != LogicalKeyboardKey.controlLeft &&
      key != LogicalKeyboardKey.controlRight &&
      key != LogicalKeyboardKey.altLeft &&
      key != LogicalKeyboardKey.altRight &&
      key != LogicalKeyboardKey.shiftLeft &&
      key != LogicalKeyboardKey.shiftRight &&
      key != LogicalKeyboardKey.metaLeft &&
      key != LogicalKeyboardKey.metaRight) {
    parts.add(keyLabel);
  }
  return parts.join('+');
}

KeyEventResult _handleExternalKeyboard(KeyEvent event, QsoFormController c) {
  if (event is! KeyDownEvent) return KeyEventResult.ignored;

  // ESC always triggers CLR
  if (event.logicalKey == LogicalKeyboardKey.escape) {
    c.clearForm();
    return KeyEventResult.handled;
  }

  final keyString = _keyEventToString(event);
  if (keyString.isEmpty) return KeyEventResult.ignored;

  // Check mappings
  final mappings = {
    'cq': c.sendCq,
    'mycall': c.sendMyCall,
    'custom': c.sendCwCustomText,
    'rpt': c.sendRprtOnly,
    'call': c.sendHisCall,
    'send': c.sendCallPlusRprt,
  };

  for (final entry in mappings.entries) {
    final savedKey = _extKeyStorage.read<String>('ext_key_${entry.key}');
    if (savedKey != null && savedKey == keyString) {
      entry.value();
      return KeyEventResult.handled;
    }
  }

  return KeyEventResult.ignored;
}

class QsoForm extends StatelessWidget {
  const QsoForm({super.key});

  Widget _buildServiceToggle(
    String label,
    bool active,
    RxBool flashTrigger,
    VoidCallback onTap,
  ) {
    return Obx(() {
      final isFlashing = flashTrigger.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isFlashing ? 1.1 : 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildButton(String buttonId, QsoFormController c) {
    final buttonConfig = {
      'CQ': {
        'label': c.cwCqText.value.isEmpty
            ? 'CQ'
            : c.cwCqText.value.length > 6
            ? '${c.cwCqText.value.substring(0, 6)}…'
            : c.cwCqText.value,
        'color': Colors.green.shade700,
        'onPressed': c.sendCq,
      },
      'MY': {
        'label': c.selectedMyCallsign.value ?? 'MY',
        'color': Colors.grey.shade700,
        'onPressed': c.sendMyCall,
      },
      'CALL': {
        'label': 'CALL?',
        'color': Colors.blueGrey.shade700,
        'onPressed': c.sendHisCall,
      },
      'RPT': {
        'label': 'RPT#',
        'color': Colors.cyan.shade700,
        'onPressed': c.sendRprtOnly,
      },
      'CUSTOM': {
        'label': c.cwCustomText.value.length > 6
            ? '${c.cwCustomText.value.substring(0, 6)}…'
            : c.cwCustomText.value,
        'color': Colors.purple.shade700,
        'onPressed': c.sendCwCustomText,
      },
      'SEND': {
        'label': 'SEND',
        'color': Colors.deepOrange.shade700,
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
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        config['label'] as String,
        style: ButtonStyles.button,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build simulation-specific buttons (CQ, SEND, SAVE)
  Widget _buildSimulationButtons(QsoFormController c) {
    return Row(
      children: [
        // CQ Button - sends CQ + mycallsign, then random callsign twice
        Expanded(
          child: ElevatedButton(
            onPressed: () => _simulationCq(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              c.cwCqText.value.isEmpty
                  ? 'CQ'
                  : c.cwCqText.value.length > 6
                  ? '${c.cwCqText.value.substring(0, 6)}…'
                  : c.cwCqText.value,
              style: ButtonStyles.button,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // SEND Button - sends the response morse
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _simulationSend(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'SEND',
              style: ButtonStyles.button,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // ? Button - repeats callsign or number
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () => _simulationRepeat(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              '?',
              style: ButtonStyles.button,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // SAVE Button - shows comparison in simulation mode
        Expanded(
          child: ElevatedButton(
            onPressed: () => _simulationSave(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.btnLog,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'SAVE',
              style: ButtonStyles.button,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  /// Build simulation results display
  Widget _buildSimulationResults() {
    return Obx(() {
      if (simulationResultList.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Simulation Results',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                GestureDetector(
                  onTap: () => simulationResultList.clear(),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            ...simulationResultList.reversed.take(10).map((result) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    // Callsign comparison
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${result.actualCallsign}/${result.userCallsign}',
                              style: TextStyle(
                                fontSize: 10,
                                color: result.callsignCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            result.callsignCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 12,
                            color: result.callsignCorrect
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Number comparison
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${result.actualNumber}/${result.userNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: result.numberCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            result.numberCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 12,
                            color: result.numberCorrect
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Code comparison
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${result.actualCode}/${result.userCode}',
                              style: TextStyle(
                                fontSize: 10,
                                color: result.codeCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            result.codeCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 12,
                            color: result.codeCorrect
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  /// Simulation CQ: Send CQ + mycallsign (once), then wait and play random callsign
  void _simulationCq(QsoFormController c) {
    // Clear all input fields
    c.callsignController.clear();
    c.receivedInfoController.clear();
    c.xtra1Controller.clear();

    // Focus callsign field immediately
    c.callsignFocus.requestFocus();
    c.setActiveTextField(c.callsignController);

    // Run morse playback asynchronously in background
    _playSimulationCqSequence(c);
  }

  /// Async helper for CQ sequence (runs in background)
  Future<void> _playSimulationCqSequence(QsoFormController c) async {
    final morseService = MorseAudioService();

    // Reset simulation state
    simulationAwaitingResponse.value = true;
    simulationGeneratedNumber.value = '';

    // Set CQ WPM from configured slider
    morseService.setWpm(simulationCqWpm.value.round());

    // Build CQ message: Custom CQ text (or "CQ") + mycallsign (once) + K if active
    final cqText = c.cwCqText.value.isNotEmpty ? c.cwCqText.value : 'CQ';
    final myCallsign = c.selectedMyCallsign.value ?? '';
    String cqMessage = '$cqText $myCallsign';
    if (c.sendK.value) {
      cqMessage += ' K';
    }

    // Play CQ message
    await morseService.playMorse(cqMessage);
    if (!simulationActive.value) return; // Stop if simulation ended

    // Wait before the answer comes - delay depends on CQ speed
    const double answerDelayFactor = 40; // ms per WPM difference
    const int answerDelayBase = 800; // minimum delay in ms
    final delayMs =
        answerDelayBase +
        (answerDelayFactor * (38 - simulationCqWpm.value)).round();
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!simulationActive.value) return; // Stop if simulation ended

    // Set random WPM from configured range for the answer
    final minWpm = simulationMinWpm.value.round();
    final maxWpm = simulationMaxWpm.value.round();
    final randomWpm = minWpm + Random().nextInt(maxWpm - minWpm + 1);
    morseService.setWpm(randomWpm);

    // Generate random callsign
    final randomCallsign = morseService.generateRandomCallsign();
    simulationGeneratedCallsign.value = randomCallsign;

    // Play random callsign first time
    await morseService.playMorse(randomCallsign);
    if (!simulationActive.value) return; // Stop if simulation ended

    // Wait for user response - if not responded after delay, repeat callsign
    await Future.delayed(Duration(milliseconds: delayMs + 500));
    if (!simulationActive.value) return; // Stop if simulation ended

    // Check if user has clicked SEND (simulationAwaitingResponse becomes false)
    if (simulationAwaitingResponse.value) {
      // User hasn't responded, repeat the callsign
      await morseService.playMorse(randomCallsign);
    }
  }

  /// Simulation ? Button: User sends "?" and station repeats number and code
  void _simulationRepeat(QsoFormController c) {
    _playSimulationRepeatSequence(c);
  }

  /// Async helper for repeat sequence
  Future<void> _playSimulationRepeatSequence(QsoFormController c) async {
    final morseService = MorseAudioService();

    // User sends "?" at their CQ speed
    morseService.setWpm(simulationCqWpm.value.round());
    await morseService.playMorse('?');
    if (!simulationActive.value) return;

    // Wait a moment
    await Future.delayed(const Duration(milliseconds: 300));
    if (!simulationActive.value) return;

    // Station repeats at random speed
    final minWpm = simulationMinWpm.value.round();
    final maxWpm = simulationMaxWpm.value.round();
    final randomWpm = minWpm + Random().nextInt(maxWpm - minWpm + 1);
    morseService.setWpm(randomWpm);

    // If number and code were already sent, repeat them
    // Otherwise repeat the callsign
    if (simulationGeneratedNumber.value.isNotEmpty &&
        simulationGeneratedCode.value.isNotEmpty) {
      await morseService.playMorse(
        '${simulationGeneratedNumber.value} ${simulationGeneratedCode.value}',
      );
    } else if (simulationGeneratedCallsign.value.isNotEmpty) {
      await morseService.playMorse(simulationGeneratedCallsign.value);
    }
  }

  /// Simulation SEND: Send response matching the info line format
  void _simulationSend(QsoFormController c) {
    // Mark that user has responded (stop CQ repeat)
    simulationAwaitingResponse.value = false;

    // Focus NR/INFO field immediately
    c.infoFocus.requestFocus();
    c.setActiveTextField(c.receivedInfoController);

    // Run morse playback asynchronously in background
    _playSimulationSendSequence(c);
  }

  /// Async helper for SEND sequence (runs in background)
  Future<void> _playSimulationSendSequence(QsoFormController c) async {
    final morseService = MorseAudioService();

    // Use my CQ speed for sending
    morseService.setWpm(simulationCqWpm.value.round());

    // Build the send message matching info line format
    final callsign = c.callsignController.text.toUpperCase();
    final pre = c.cwPreController.text;
    final post = c.cwPostController.text;

    // Apply 9/N transformation to RST if enabled
    String rst = c.rstOutController.text;
    if (c.nineIsN.value) {
      rst = rst.replaceAll('9', 'N');
    }

    // Apply 0/T transformation to counter if enabled
    String counter = '';
    if (c.useCounter.value && c.xtra2Controller.text.isNotEmpty) {
      counter = c.xtra2Controller.text;
      if (c.zeroIsT.value) {
        counter = counter.replaceAll('0', 'T');
      }
    }

    // Get activation reference if selected
    String activationRef = '';
    final activationId = c.selectedActivationId.value;
    if (activationId != null) {
      final dbController = Get.find<DatabaseController>();
      final activation = dbController.activationList.firstWhereOrNull(
        (a) => a.id == activationId,
      );
      if (activation != null && activation.reference.isNotEmpty) {
        if (_showRefPrefix.value) {
          activationRef =
              '${activation.type.toUpperCase()} ${activation.reference.replaceAll('-', '')}';
        } else {
          activationRef = activation.reference.replaceAll('-', '');
        }
      }
    }

    // Build message: CALL PRE RST COUNT ACTIVATION POST BK
    String message = callsign;
    if (pre.isNotEmpty) message += ' $pre';
    message += ' $rst';
    if (counter.isNotEmpty) message += ' $counter';
    if (activationRef.isNotEmpty) message += ' $activationRef';
    if (post.isNotEmpty) message += ' $post';
    if (c.sendBK.value) message += ' BK';

    // Play the message
    await morseService.playMorse(message);
    if (!simulationActive.value) return;

    // Wait 400ms then answer with 599 + 3-digit number + code (2 letters + 5 numbers)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!simulationActive.value) return;

    // Set random WPM from configured range for the answer
    final minWpm = simulationMinWpm.value.round();
    final maxWpm = simulationMaxWpm.value.round();
    final randomWpm = minWpm + Random().nextInt(maxWpm - minWpm + 1);
    morseService.setWpm(randomWpm);

    // Generate 3-digit random number (100-999)
    final randomNumber = (100 + Random().nextInt(900)).toString();
    simulationGeneratedNumber.value = randomNumber;

    // Generate code: 2 letters + 5 numbers
    final random = Random();
    final letter1 = String.fromCharCode(65 + random.nextInt(26));
    final letter2 = String.fromCharCode(65 + random.nextInt(26));
    final numbers = List.generate(5, (_) => random.nextInt(10)).join();
    final randomCode = '$letter1$letter2$numbers';
    simulationGeneratedCode.value = randomCode;

    // Build RST: 599, or 5NN if 9/N is active
    String stationRst = '599';
    if (c.nineIsN.value) {
      stationRst = '5NN';
    }

    // Apply 0/T transformation to number if active
    String numberToSend = randomNumber;
    if (c.zeroIsT.value) {
      numberToSend = randomNumber.replaceAll('0', 'T');
    }

    // Play: RST + number + code
    await morseService.playMorse('$stationRst $numberToSend $randomCode');
  }

  /// Simulation SAVE: Show comparison, send TU, and trigger next station
  void _simulationSave(QsoFormController c) {
    // Get user input
    final userCallsign = c.callsignController.text.trim().toUpperCase();
    final userNumber = c.receivedInfoController.text.trim();
    final userCode = c.xtra1Controller.text.trim().toUpperCase();

    // Get generated values
    final actualCallsign = simulationGeneratedCallsign.value;
    final actualNumber = simulationGeneratedNumber.value;
    final actualCode = simulationGeneratedCode.value;

    // Create result and add to list
    final result = SimulationResult(
      actualCallsign: actualCallsign,
      userCallsign: userCallsign,
      actualNumber: actualNumber,
      userNumber: userNumber,
      actualCode: actualCode,
      userCode: userCode,
    );
    simulationResultList.add(result);

    // Clear form for next QSO
    c.callsignController.clear();
    c.receivedInfoController.clear();
    c.xtra1Controller.clear();
    simulationGeneratedCallsign.value = '';
    simulationGeneratedNumber.value = '';
    simulationGeneratedCode.value = '';

    // Increment counter if active
    if (c.useCounter.value && c.xtra2Controller.text.isNotEmpty) {
      final current = int.tryParse(c.xtra2Controller.text) ?? 0;
      c.xtra2Controller.text = (current + 1).toString().padLeft(3, '0');
    }

    // Focus callsign field for next QSO
    c.callsignFocus.requestFocus();
    c.setActiveTextField(c.callsignController);

    // Increment save count and send TU (+ CQ every 3rd click)
    simulationSaveCount.value++;
    _playSimulationSaveSequence(c);
  }

  /// Async helper for SAVE sequence - sends TU and triggers next station
  Future<void> _playSimulationSaveSequence(QsoFormController c) async {
    final morseService = MorseAudioService();

    // Use my CQ speed for sending
    morseService.setWpm(simulationCqWpm.value.round());

    // Build message: TU, and every 3rd save add CQ DE MYCALL
    final myCallsign = c.selectedMyCallsign.value ?? '';
    String message = 'TU';
    if (simulationSaveCount.value % 3 == 0) {
      message = 'TU CQ DE $myCallsign';
      if (c.sendK.value) {
        message += ' K';
      }
    }

    // Play TU message
    await morseService.playMorse(message);
    if (!simulationActive.value) return;

    // Wait 300ms then next station answers
    await Future.delayed(const Duration(milliseconds: 300));
    if (!simulationActive.value) return;

    // Set random WPM from configured range for the answer
    final minWpm = simulationMinWpm.value.round();
    final maxWpm = simulationMaxWpm.value.round();
    final randomWpm = minWpm + Random().nextInt(maxWpm - minWpm + 1);
    morseService.setWpm(randomWpm);

    // Generate new random callsign
    final randomCallsign = morseService.generateRandomCallsign();
    simulationGeneratedCallsign.value = randomCallsign;
    simulationGeneratedNumber.value = '';
    simulationAwaitingResponse.value = true;

    // Play new random callsign
    await morseService.playMorse(randomCallsign);
    if (!simulationActive.value) return;

    // Wait and repeat if user hasn't responded
    const double answerDelayFactor = 40;
    const int answerDelayBase = 800;
    final delayMs =
        answerDelayBase +
        (answerDelayFactor * (38 - simulationCqWpm.value)).round();
    await Future.delayed(Duration(milliseconds: delayMs + 500));
    if (!simulationActive.value) return;

    if (simulationAwaitingResponse.value) {
      await morseService.playMorse(randomCallsign);
    }
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

    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) => _handleExternalKeyboard(event, c),
      child: Column(
        children: [
          Expanded(
            child: Form(
              key: c.formKey,
              child: Column(
                children: [
                  // Top row: Bluetooth, My Callsign, Status
                  Obx(() {
                    final isDark = Get.find<ThemeController>().isDarkMode.value;
                    return Container(
                      color: isDark ? Colors.black : AppColors.surfaceLight,
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
                                        onPressed: () => Get.to(
                                          () => const MyCallsignsScreen(),
                                        ),
                                        child: const Text('add call'),
                                      )
                                    : DropdownButtonFormField<String>(
                                        value: c.selectedMyCallsign.value,
                                        decoration: InputStyles.dropdownFilled(
                                          '',
                                          AppColors.dropdownCallsign,
                                        ),
                                        isExpanded: true,
                                        dropdownColor:
                                            AppColors.dropdownCallsign,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
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
                                final dbController =
                                    Get.find<DatabaseController>();
                                final activations = dbController.activationList
                                    .where((a) => a.showInDropdown)
                                    .toList();
                                return DropdownButtonFormField<int?>(
                                  value: c.selectedActivationId.value,
                                  decoration: InputStyles.dropdownFilled(
                                    '',
                                    AppColors.dropdownActivation,
                                  ),
                                  isExpanded: true,
                                  dropdownColor: AppColors.dropdownActivation,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  itemHeight: 56,
                                  selectedItemBuilder: (context) {
                                    return [
                                      const Text('no activation'),
                                      ...activations.map((a) {
                                        return Text(
                                          a.reference,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }),
                                    ];
                                  },
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                borderRadius:
                                                    BorderRadius.circular(3),
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
                    );
                  }),
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
                              builder: (context, callsignValue, child) => ValueListenableBuilder<TextEditingValue>(
                                valueListenable: c.rstOutController,
                                builder: (context, rstValue, child) => ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: c.xtra2Controller,
                                  builder: (context, countValue, child) =>
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: c.cwPreController,
                                        builder: (context, preValue, child) =>
                                            ValueListenableBuilder<
                                              TextEditingValue
                                            >(
                                              valueListenable:
                                                  c.cwPostController,
                                              builder: (context, postValue, child) =>
                                                  ValueListenableBuilder<
                                                    TextEditingValue
                                                  >(
                                                    valueListenable:
                                                        c.locatorController,
                                                    builder: (context, locatorValue, child) => Obx(() {
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
                                                      String locatorText = '';
                                                      if (_sendLocator.value &&
                                                          locatorValue
                                                              .text
                                                              .isNotEmpty) {
                                                        locatorText =
                                                            ' ${locatorValue.text.toUpperCase()}';
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
                                                        '${callsignValue.text.toUpperCase()} $preText$rstText$countText$locatorText$activationRef$postText$bkText'
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

                  // Service indicators row (hidden in contest mode and simulation mode)
                  Obx(() {
                    // Trigger rebuild when callsign changes
                    c.selectedMyCallsign.value;
                    if (c.contestMode.value) return const SizedBox.shrink();
                    if (simulationActive.value && simulationPaused.value)
                      return const SizedBox.shrink();
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
                          _buildServiceToggle(
                            'Clublog',
                            c.useClublog,
                            c.clublogFlash,
                            c.toggleClublog,
                          ),
                          const SizedBox(width: 4),
                          _buildServiceToggle(
                            'eQSL',
                            c.useEqsl,
                            c.eqslFlash,
                            c.toggleEqsl,
                          ),
                          const SizedBox(width: 4),
                          _buildServiceToggle(
                            'LoTW',
                            c.useLotw,
                            c.lotwFlash,
                            c.toggleLotw,
                          ),
                          const Spacer(),
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
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
                                        : const Icon(
                                            Icons.my_location,
                                            size: 24,
                                          ),
                                  ),
                                ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send locator toggle
                          Obx(
                            () => GestureDetector(
                              onTap: () {
                                _sendLocator.value = !_sendLocator.value;
                                _storage.write(
                                  'send_locator',
                                  _sendLocator.value,
                                );
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _sendLocator.value
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                ),
                                child: const Center(
                                  child: Text(
                                    'LOC',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
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
                    final isDark = Get.find<ThemeController>().isDarkMode.value;
                    return Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDark ? Colors.black : AppColors.surfaceLight,
                      child: Row(
                        children: [
                          Obx(
                            () => Text(
                              '${btController.cwSpeed.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : null,
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
                                child: RoundToggleRow(
                                  toggles: [
                                    RoundToggle(label: '0/T', value: c.zeroIsT),
                                    RoundToggle(label: '9/N', value: c.nineIsN),
                                    RoundToggle(label: 'BK', value: c.sendBK),
                                    RoundToggle(label: 'K', value: c.sendK),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 56,
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
                                  onChanged: (v) =>
                                      c.saveCwPre(v.toUpperCase()),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 56,
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
                                  onChanged: (v) =>
                                      c.saveCwPost(v.toUpperCase()),
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
                                  ? InputStyles.fieldFilled(
                                      'Callsign',
                                    ).copyWith(
                                      filled: true,
                                      fillColor: Colors.red,
                                    )
                                  : InputStyles.fieldFilled(
                                      'Callsign',
                                    ).copyWith(
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
                  // Row 2: Received Info, Xtra1, SPC, 2nd
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: P.fieldTight,
                          child: Obx(
                            () => TextFormField(
                              controller: c.receivedInfoController,
                              focusNode: c.infoFocus,
                              textCapitalization: TextCapitalization.characters,
                              readOnly: c.useCustomKeyboard.value,
                              showCursor: true,
                              decoration: InputStyles.field('NR / INFO'),
                              inputFormatters: [UpperCaseTextFormatter()],
                              onTap: () => c.setActiveTextField(
                                c.receivedInfoController,
                              ),
                              onChanged: c.onInfoChanged,
                              onFieldSubmitted: (_) => c.submitQso(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: P.fieldTight,
                          child: Obx(
                            () => TextFormField(
                              controller: c.xtra1Controller,
                              focusNode: c.xtra1Focus,
                              textCapitalization: TextCapitalization.characters,
                              readOnly: c.useCustomKeyboard.value,
                              showCursor: true,
                              decoration: InputStyles.field('Xtra 1'),
                              inputFormatters: [UpperCaseTextFormatter()],
                              onTap: () =>
                                  c.setActiveTextField(c.xtra1Controller),
                              onChanged: c.onXtra1Changed,
                            ),
                          ),
                        ),
                      ),
                      // Jump mode dropdown
                      Obx(() {
                        // Access callsignList to rebuild when settings change
                        Get.find<DatabaseController>().callsignList.length;
                        return Container(
                          height: 38,
                          margin: const EdgeInsets.only(left: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: c.jumpMode == 'none'
                                ? Colors.grey.shade400
                                : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<String>(
                            value: c.jumpMode,
                            underline: const SizedBox(),
                            isDense: false,
                            dropdownColor: Colors.grey.shade800,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 16,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text('none'),
                              ),
                              DropdownMenuItem(
                                value: 'SPC',
                                child: Text('SPC'),
                              ),
                              DropdownMenuItem(
                                value: '2nd',
                                child: Text('2nd'),
                              ),
                              DropdownMenuItem(
                                value: 'jump',
                                child: Text('jump'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) c.setJumpMode(value);
                            },
                          ),
                        );
                      }),
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
                                        decoration:
                                            InputStyles.field(
                                              'YYYYMMDD',
                                            ).copyWith(
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
                                        onTap: () =>
                                            _showDatePicker(context, c),
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
                                        onTap: () =>
                                            _showTimePicker(context, c),
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
                  // Row 4: Band, Mode dropdowns (hidden in simulation mode)
                  Obx(() {
                    if (simulationActive.value && simulationPaused.value) {
                      return const SizedBox.shrink();
                    }
                    return Row(
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
                                      decoration: InputStyles.dropdownFilled(
                                        'Sat',
                                        AppColors.dropdownSatellite,
                                      ),
                                      isExpanded: true,
                                      dropdownColor:
                                          AppColors.dropdownSatellite,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
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
                    );
                  }),
                  SizedBox(height: P.lineSpacing),
                  // Dynamic button rows based on saved layout
                  Obx(() {
                    // If simulation is active and playing, show simulation buttons
                    if (simulationActive.value && simulationPaused.value) {
                      return Column(
                        children: [
                          _buildSimulationButtons(c),
                          _buildSimulationResults(),
                        ],
                      );
                    }

                    final btController = Get.find<BluetoothController>();
                    final isCwMode = c.selectedMode.value == 'CW';
                    final isConnected = btController.isConnected.value;
                    final rows = c.buttonLayoutRows.value;

                    // Check if button should be visible
                    bool isButtonVisible(String buttonId) {
                      if (buttonId == 'CUSTOM' &&
                          c.cwCustomText.value.isEmpty) {
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

                        // Filter to only visible buttons in this row
                        final visibleButtons = row
                            .where((b) => isButtonVisible(b))
                            .toList();

                        return Row(
                          children: visibleButtons
                              .map(
                                (buttonId) => Expanded(
                                  child: _buildButton(buttonId, c),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    );
                  }),
                  // Matching QSOs list - takes remaining space
                  Expanded(
                    child: Obx(() {
                      if (c.matchingQsos.isEmpty)
                        return const SizedBox.shrink();
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
                                        color: isExactMatch
                                            ? Colors.white
                                            : null,
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
      ),
    );
  }
}
