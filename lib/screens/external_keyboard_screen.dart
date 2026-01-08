import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ExternalKeyboardScreen extends StatefulWidget {
  const ExternalKeyboardScreen({super.key});

  @override
  State<ExternalKeyboardScreen> createState() => _ExternalKeyboardScreenState();
}

class _ExternalKeyboardScreenState extends State<ExternalKeyboardScreen> {
  final _storage = GetStorage();
  final _focusNode = FocusNode();

  // Button IDs and their display names
  static const List<Map<String, String>> _buttons = [
    {'id': 'cq', 'name': 'CQ'},
    {'id': 'mycall', 'name': 'MY CALLSIGN'},
    {'id': 'custom', 'name': 'Individuell'},
    {'id': 'rpt', 'name': 'RPT#'},
    {'id': 'call', 'name': 'CALL'},
    {'id': 'send', 'name': 'SEND'},
  ];

  // Current mappings (button id -> key description)
  final Map<String, String> _mappings = {};

  // Currently mapping button (null if not mapping)
  String? _currentlyMapping;

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _loadMappings() {
    for (final button in _buttons) {
      final saved = _storage.read<String>('ext_key_${button['id']}');
      if (saved != null) {
        _mappings[button['id']!] = saved;
      }
    }
    setState(() {});
  }

  void _saveMappings() {
    for (final entry in _mappings.entries) {
      _storage.write('ext_key_${entry.key}', entry.value);
    }
    Get.back();
    Get.snackbar(
      'Saved',
      'Keyboard mappings saved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _startMapping(String buttonId) {
    setState(() {
      _currentlyMapping = buttonId;
    });
    _focusNode.requestFocus();
  }

  void _cancelMapping() {
    setState(() {
      _currentlyMapping = null;
    });
  }

  void _clearMapping(String buttonId) {
    setState(() {
      _mappings.remove(buttonId);
    });
    _storage.remove('ext_key_$buttonId');
  }

  String _keyEventToString(KeyEvent event) {
    final List<String> parts = [];

    // Check modifiers
    if (HardwareKeyboard.instance.isControlPressed) {
      parts.add('Ctrl');
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      parts.add('Alt');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      parts.add('Shift');
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      parts.add('Meta');
    }

    // Get the key label
    final key = event.logicalKey;
    String keyLabel = key.keyLabel;

    // Handle special keys
    if (keyLabel.isEmpty) {
      keyLabel = key.debugName ?? 'Unknown';
    }

    // Don't add modifier keys as the main key
    if (!_isModifierKey(key)) {
      parts.add(keyLabel);
    }

    return parts.join('+');
  }

  bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.controlLeft ||
           key == LogicalKeyboardKey.controlRight ||
           key == LogicalKeyboardKey.altLeft ||
           key == LogicalKeyboardKey.altRight ||
           key == LogicalKeyboardKey.shiftLeft ||
           key == LogicalKeyboardKey.shiftRight ||
           key == LogicalKeyboardKey.metaLeft ||
           key == LogicalKeyboardKey.metaRight;
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (_currentlyMapping == null) return KeyEventResult.ignored;

    // Only handle key down events
    if (event is! KeyDownEvent) return KeyEventResult.handled;

    // Escape cancels mapping
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelMapping();
      return KeyEventResult.handled;
    }

    // Ignore pure modifier key presses
    if (_isModifierKey(event.logicalKey)) {
      return KeyEventResult.handled;
    }

    final keyString = _keyEventToString(event);
    if (keyString.isNotEmpty) {
      setState(() {
        _mappings[_currentlyMapping!] = keyString;
        _currentlyMapping = null;
      });
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(title: const Text('External Keyboard')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Map external keyboard keys to CW buttons.\nCLR is always triggered by ESC.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Mapping rows
              Expanded(
                child: ListView(
                  children: [
                    ..._buttons.map((button) => _buildMappingRow(
                      button['id']!,
                      button['name']!,
                    )),
                    // CLR row (hardcoded to ESC)
                    _buildFixedRow('CLR', 'Escape'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Save button
              FilledButton.icon(
                onPressed: _saveMappings,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMappingRow(String buttonId, String buttonName) {
    final isMapping = _currentlyMapping == buttonId;
    final currentMapping = _mappings[buttonId];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMapping ? Colors.orange.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: isMapping ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Row(
        children: [
          // Button name
          SizedBox(
            width: 120,
            child: Text(
              buttonName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Current mapping or waiting indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                isMapping
                    ? 'Press a key...'
                    : currentMapping ?? '-',
                style: TextStyle(
                  color: isMapping ? Colors.orange : Colors.black87,
                  fontStyle: isMapping ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Map button
          if (!isMapping)
            TextButton(
              onPressed: () => _startMapping(buttonId),
              child: const Text('Map'),
            )
          else
            TextButton(
              onPressed: _cancelMapping,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel'),
            ),

          // Clear button
          if (currentMapping != null && !isMapping)
            IconButton(
              onPressed: () => _clearMapping(buttonId),
              icon: const Icon(Icons.clear, size: 18),
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildFixedRow(String buttonName, String mapping) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              buttonName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(mapping),
            ),
          ),
          const SizedBox(width: 8),
          const TextButton(
            onPressed: null,
            child: Text('Fixed', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
