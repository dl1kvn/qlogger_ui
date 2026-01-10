import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/callsign_model.dart';
import 'lotw_setup_screen.dart';

class CallsignEditScreen extends StatefulWidget {
  final CallsignModel? callsign;

  const CallsignEditScreen({super.key, this.callsign});

  @override
  State<CallsignEditScreen> createState() => _CallsignEditScreenState();
}

class _CallsignEditScreenState extends State<CallsignEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbController = Get.find<DatabaseController>();

  late final TextEditingController _callsignController;
  late final TextEditingController _clublogemailController;
  late final TextEditingController _clublogpwController;
  late final TextEditingController _eqsluserController;
  late final TextEditingController _eqslpasswordController;
  late final TextEditingController _lotwloginController;
  late final TextEditingController _lotwpwController;
  late final TextEditingController _lotwcertController;
  late final TextEditingController _lotwkeyController;
  late final TextEditingController _ituController;
  late final TextEditingController _cqzoneController;
  late final TextEditingController _cwCustomTextController;
  late final TextEditingController _cwCqTextController;

  late bool _useClublog;
  late bool _useEqsl;
  late bool _useLotw;
  late List<String> _selectedModes;
  late List<String> _selectedBands;
  late bool _useCounter;
  late bool _zeroIsT;
  late bool _nineIsN;
  late bool _sendK;
  late bool _sendBK;
  late bool _singleRst;
  late bool _useSpacebarToggle;
  late bool _toggleSecondField;
  late bool _useCqzones;
  late bool _useItuzones;
  late bool _useGermanKeyboard;
  late List<List<String>> _buttonLayoutRows;

  bool get isEditing => widget.callsign != null;

  bool get _clublogFieldsFilled =>
      _clublogemailController.text.isNotEmpty &&
      _clublogpwController.text.isNotEmpty;

  bool get _eqslFieldsFilled =>
      _eqsluserController.text.isNotEmpty &&
      _eqslpasswordController.text.isNotEmpty;

  bool get _lotwFieldsFilled =>
      _lotwloginController.text.isNotEmpty &&
      _lotwpwController.text.isNotEmpty &&
      _lotwcertController.text.isNotEmpty;

  void _onServiceFieldChanged() {
    setState(() {
      // Turn off switches if fields become empty
      if (!_clublogFieldsFilled) _useClublog = false;
      if (!_eqslFieldsFilled) _useEqsl = false;
      if (!_lotwFieldsFilled) _useLotw = false;
    });
  }

  @override
  void initState() {
    super.initState();
    final c = widget.callsign;
    _callsignController = TextEditingController(text: c?.callsign ?? '');
    _clublogemailController = TextEditingController(
      text: c?.clublogemail ?? '',
    );
    _clublogpwController = TextEditingController(text: c?.clublogpw ?? '');
    _eqsluserController = TextEditingController(text: c?.eqsluser ?? '');
    _eqslpasswordController = TextEditingController(
      text: c?.eqslpassword ?? '',
    );
    _lotwloginController = TextEditingController(text: c?.lotwlogin ?? '');
    _lotwpwController = TextEditingController(text: c?.lotwpw ?? '');
    _lotwcertController = TextEditingController(text: c?.lotwcert ?? '');
    _lotwkeyController = TextEditingController(text: c?.lotwkey ?? '');
    _ituController = TextEditingController(text: c?.itu ?? '');
    _cqzoneController = TextEditingController(text: c?.cqzone ?? '');
    _cwCustomTextController = TextEditingController(
      text: c?.cwCustomText ?? '',
    );
    _cwCqTextController = TextEditingController(text: c?.cwCqText ?? '');
    _useClublog = (c?.useclublog ?? 0) == 1;
    _useEqsl = (c?.useeqsl ?? 0) == 1;
    _useLotw = (c?.uselotw ?? 0) == 1;
    _selectedModes = c?.modesList ?? ['CW', 'SSB'];
    _selectedBands = c?.bandsList ?? CallsignModel.defaultBands.split(',');
    _useCounter = (c?.useCounter ?? 0) == 1;
    _zeroIsT = (c?.zeroIsT ?? 0) == 1;
    _nineIsN = (c?.nineIsN ?? 0) == 1;
    _sendK = (c?.sendK ?? 0) == 1;
    _sendBK = (c?.sendBK ?? 0) == 1;
    _singleRst = (c?.singleRst ?? 0) == 1;
    _useSpacebarToggle = (c?.useSpacebarToggle ?? 0) == 1;
    _toggleSecondField = (c?.toggleSecondField ?? 0) == 1;
    _useCqzones = (c?.useCqzones ?? 0) == 1;
    _useItuzones = (c?.useItuzones ?? 0) == 1;
    _useGermanKeyboard = (c?.useGermanKeyboard ?? 0) == 1;
    _buttonLayoutRows =
        c?.buttonLayoutRows ??
        [
          ['CQ', 'MY', 'CALL', 'RPT', 'CUSTOM'],
          ['SEND', 'CLR', 'SAVE'],
          [],
        ];

    // Add listeners to update switch states when fields change
    _clublogemailController.addListener(_onServiceFieldChanged);
    _clublogpwController.addListener(_onServiceFieldChanged);
    _eqsluserController.addListener(_onServiceFieldChanged);
    _eqslpasswordController.addListener(_onServiceFieldChanged);
    _lotwloginController.addListener(_onServiceFieldChanged);
    _lotwpwController.addListener(_onServiceFieldChanged);
    _lotwcertController.addListener(_onServiceFieldChanged);
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _clublogemailController.removeListener(_onServiceFieldChanged);
    _clublogpwController.removeListener(_onServiceFieldChanged);
    _eqsluserController.removeListener(_onServiceFieldChanged);
    _eqslpasswordController.removeListener(_onServiceFieldChanged);
    _lotwloginController.removeListener(_onServiceFieldChanged);
    _lotwpwController.removeListener(_onServiceFieldChanged);
    _lotwcertController.removeListener(_onServiceFieldChanged);

    _callsignController.dispose();
    _clublogemailController.dispose();
    _clublogpwController.dispose();
    _eqsluserController.dispose();
    _eqslpasswordController.dispose();
    _lotwloginController.dispose();
    _lotwpwController.dispose();
    _lotwcertController.dispose();
    _lotwkeyController.dispose();
    _ituController.dispose();
    _cqzoneController.dispose();
    _cwCustomTextController.dispose();
    _cwCqTextController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate service fields if enabled
    final errors = <String>[];
    if (_useClublog && !_clublogFieldsFilled) {
      errors.add('Club Log requires email and password');
    }
    if (_useEqsl && !_eqslFieldsFilled) {
      errors.add('eQSL requires user and password');
    }
    if (_useLotw && !_lotwFieldsFilled) {
      errors.add('LoTW requires login, password and certificate');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final callsign = CallsignModel(
      id: widget.callsign?.id,
      callsign: _callsignController.text.toUpperCase(),
      clublogemail: _clublogemailController.text,
      clublogpw: _clublogpwController.text,
      useclublog: _useClublog ? 1 : 0,
      eqsluser: _eqsluserController.text,
      eqslpassword: _eqslpasswordController.text,
      useeqsl: _useEqsl ? 1 : 0,
      lotwlogin: _lotwloginController.text,
      lotwpw: _lotwpwController.text,
      lotwcert: _lotwcertController.text,
      lotwkey: _lotwkeyController.text,
      uselotw: _useLotw ? 1 : 0,
      itu: _ituController.text,
      cqzone: _cqzoneController.text,
      modes: _selectedModes.join(','),
      bands: _selectedBands.join(','),
      useCounter: _useCounter ? 1 : 0,
      zeroIsT: _zeroIsT ? 1 : 0,
      nineIsN: _nineIsN ? 1 : 0,
      sendK: _sendK ? 1 : 0,
      sendBK: _sendBK ? 1 : 0,
      singleRst: _singleRst ? 1 : 0,
      useSpacebarToggle: _useSpacebarToggle ? 1 : 0,
      toggleSecondField: _toggleSecondField ? 1 : 0,
      useCqzones: _useCqzones ? 1 : 0,
      useItuzones: _useItuzones ? 1 : 0,
      useGermanKeyboard: _useGermanKeyboard ? 1 : 0,
      cwCustomText: _cwCustomTextController.text.toUpperCase(),
      cwCqText: _cwCqTextController.text.toUpperCase(),
      cwButtonLayout: _buttonLayoutRows.map((r) => r.join(',')).join('|'),
    );

    bool success;
    if (isEditing) {
      success = await _dbController.updateCallsign(callsign);
    } else {
      success = await _dbController.addCallsign(callsign);
    }

    if (success) {
      Get.back();
    }
  }

  Future<void> _delete() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Callsign'),
        content: Text('Delete ${widget.callsign!.callsign}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbController.deleteCallsign(widget.callsign!.id!);
      Get.back();
    }
  }

  void _toggleMode(String mode) {
    setState(() {
      if (_selectedModes.contains(mode)) {
        _selectedModes.remove(mode);
      } else {
        _selectedModes.add(mode);
      }
    });
  }

  void _toggleBand(String band) {
    setState(() {
      if (_selectedBands.contains(band)) {
        _selectedBands.remove(band);
      } else {
        _selectedBands.add(band);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Callsign' : 'Add Callsign'),
        actions: [
          if (isEditing)
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _callsignController,
              decoration: const InputDecoration(
                labelText: 'Callsign',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: newValue.text.toUpperCase(),
                  ),
                ),
              ],
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ituController,
                    decoration: const InputDecoration(
                      labelText: 'ITU Zone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cqzoneController,
                    decoration: const InputDecoration(
                      labelText: 'CQ Zone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cwCqTextController,
              decoration: const InputDecoration(
                labelText: 'Custom CQ Button Text',
                hintText: 'CQ TEST...',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: newValue.text.toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cwCustomTextController,
              decoration: const InputDecoration(
                labelText: 'Custom CW Button Text',
                hintText: 'e.g. TU 73 GL',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: newValue.text.toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Modes (drag to reorder)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildReorderableChips(
              items: _selectedModes,
              allItems: CallsignModel.allModes,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedModes.removeAt(oldIndex);
                  _selectedModes.insert(newIndex, item);
                });
              },
              onToggle: _toggleMode,
            ),
            const SizedBox(height: 24),
            Text(
              'Bands (drag to reorder)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildReorderableChips(
              items: _selectedBands,
              allItems: CallsignModel.allBands,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedBands.removeAt(oldIndex);
                  _selectedBands.insert(newIndex, item);
                });
              },
              onToggle: _toggleBand,
              suffix: ' MHz',
            ),
            const SizedBox(height: 24),
            Text(
              'General Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Single RST'),
              subtitle: const Text(
                'Select only the signal strength digit when clicking IN/OUT',
              ),
              value: _singleRst,
              onChanged: (v) => setState(() => _singleRst = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Use CQ Zones'),
              subtitle: const Text(
                'Auto-fill CQ zone in NR/INFO based on callsign prefix',
              ),
              value: _useCqzones,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _useCqzones = true;
                  _useItuzones = false;
                } else {
                  _useCqzones = false;
                }
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Use ITU Zones'),
              subtitle: const Text(
                'Auto-fill ITU zone in NR/INFO based on callsign prefix',
              ),
              value: _useItuzones,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _useItuzones = true;
                  _useCqzones = false;
                } else {
                  _useItuzones = false;
                }
              }),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('German Keyboard Layout'),
              subtitle: const Text('Swap Y and Z keys (QWERTZ)'),
              value: _useGermanKeyboard,
              onChanged: (v) => setState(() => _useGermanKeyboard = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Text('CW Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('#'),
                  selected: _useCounter,
                  onSelected: (v) => setState(() => _useCounter = v),
                ),
                FilterChip(
                  label: const Text('0/t'),
                  selected: _zeroIsT,
                  onSelected: (v) => setState(() => _zeroIsT = v),
                ),
                FilterChip(
                  label: const Text('9/n'),
                  selected: _nineIsN,
                  onSelected: (v) => setState(() => _nineIsN = v),
                ),
                FilterChip(
                  label: const Text('K'),
                  selected: _sendK,
                  onSelected: (v) => setState(() => _sendK = v),
                ),
                FilterChip(
                  label: const Text('BK'),
                  selected: _sendBK,
                  onSelected: (v) => setState(() => _sendBK = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'CW Button Layout (drag to reorder)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildButtonLayoutEditor(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'Club Log',
              _useClublog,
              (v) => setState(() => _useClublog = v),
              enabled: _clublogFieldsFilled,
              disabledHint: 'Fill email and password to enable',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _clublogemailController,
              decoration: const InputDecoration(
                labelText: 'Club Log Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clublogpwController,
              decoration: const InputDecoration(
                labelText: 'Club Log Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _buildCopyFromDropdown(
              otherCallsigns: _dbController.callsignList
                  .where((c) =>
                      c.id != widget.callsign?.id &&
                      c.clublogemail.isNotEmpty &&
                      c.clublogpw.isNotEmpty)
                  .toList(),
              onCopy: (callsign) {
                setState(() {
                  _clublogemailController.text = callsign.clublogemail;
                  _clublogpwController.text = callsign.clublogpw;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'eQSL',
              _useEqsl,
              (v) => setState(() => _useEqsl = v),
              enabled: _eqslFieldsFilled,
              disabledHint: 'Fill user and password to enable',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _eqsluserController,
              decoration: const InputDecoration(
                labelText: 'eQSL User',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _eqslpasswordController,
              decoration: const InputDecoration(
                labelText: 'eQSL Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _buildCopyFromDropdown(
              otherCallsigns: _dbController.callsignList
                  .where((c) =>
                      c.id != widget.callsign?.id &&
                      c.eqsluser.isNotEmpty &&
                      c.eqslpassword.isNotEmpty)
                  .toList(),
              onCopy: (callsign) {
                setState(() {
                  _eqsluserController.text = callsign.eqsluser;
                  _eqslpasswordController.text = callsign.eqslpassword;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'LoTW',
              _useLotw,
              (v) => setState(() => _useLotw = v),
              enabled: _lotwFieldsFilled,
              disabledHint: 'Fill login, password and load certificate to enable',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lotwloginController,
              decoration: const InputDecoration(
                labelText: 'LoTW Login',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lotwpwController,
              decoration: const InputDecoration(
                labelText: 'LoTW Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lotwcertController,
              decoration: const InputDecoration(
                labelText: 'LoTW Certificate (P12)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              minLines: 2,
              readOnly: true,
            ),
            if (_lotwcertController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Key saved in store',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Get.to<LotwSetupResult>(
                  () => LotwSetupScreen(callsign: _callsignController.text),
                );
                if (result != null) {
                  setState(() {
                    _lotwcertController.text = result.certificate;
                    _lotwkeyController.text = result.privateKey; // P12 password
                  });
                }
              },
              icon: const Icon(Icons.key),
              label: const Text('Load P12 File'),
            ),
            const SizedBox(height: 8),
            Text(
              'Export P12 from TQSL with a password (required for signing)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _save,
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyFromDropdown({
    required List<CallsignModel> otherCallsigns,
    required void Function(CallsignModel) onCopy,
  }) {
    if (otherCallsigns.isEmpty) {
      return const SizedBox.shrink();
    }

    CallsignModel? selectedCallsign;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<CallsignModel>(
                value: selectedCallsign,
                decoration: const InputDecoration(
                  labelText: 'Copy from other callsign',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                isExpanded: true,
                hint: const Text('Choose from other calls'),
                items: otherCallsigns.map((c) {
                  return DropdownMenuItem<CallsignModel>(
                    value: c,
                    child: Text(c.callsign),
                  );
                }).toList(),
                onChanged: (v) {
                  setLocalState(() => selectedCallsign = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: selectedCallsign != null
                  ? () => onCopy(selectedCallsign!)
                  : null,
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
    String? disabledHint,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (!enabled && disabledHint != null)
                Text(
                  disabledHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildReorderableChips({
    required List<String> items,
    required List<String> allItems,
    required void Function(int, int) onReorder,
    required void Function(String) onToggle,
    String suffix = '',
  }) {
    final unselectedItems = allItems
        .where((item) => !items.contains(item))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected items - reorderable
        if (items.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: onReorder,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return ReorderableDragStartListener(
                key: ValueKey(item),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Chip(
                    avatar: const Icon(Icons.drag_handle, size: 18),
                    label: Text('$item$suffix'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => onToggle(item),
                  ),
                ),
              );
            },
          ),
        // Unselected items - add chips
        if (unselectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: unselectedItems.map((item) {
              return ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: Text('$item$suffix'),
                onPressed: () => onToggle(item),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildButtonLayoutEditor() {
    final buttonLabels = {
      'CQ': 'CQ',
      'MY': 'MY',
      'CALL': 'CALL?',
      'RPT': 'RPT#',
      'CUSTOM': _cwCustomTextController.text.isEmpty
          ? 'CUSTOM'
          : _cwCustomTextController.text.length > 6
          ? '${_cwCustomTextController.text.substring(0, 6)}…'
          : _cwCustomTextController.text,
      'SEND': 'SEND',
      'CLR': 'CLR',
      'SAVE': 'SAVE',
    };

    final customDisabled = _cwCustomTextController.text.isEmpty;
    final buttonColors = {
      'CQ': Colors.green,
      'MY': Colors.grey,
      'CALL': Colors.blueGrey,
      'RPT': Colors.cyan,
      'CUSTOM': customDisabled ? Colors.grey.shade400 : Colors.purple,
      'SEND': Colors.deepOrangeAccent,
      'CLR': Colors.red.shade300,
      'SAVE': Colors.blue,
    };

    return Column(
      children: List.generate(3, (rowIndex) {
        return DragTarget<Map<String, dynamic>>(
          onAcceptWithDetails: (details) {
            final data = details.data;
            final fromRow = data['row'] as int;
            final buttonId = data['button'] as String;

            setState(() {
              // Remove from original position
              _buttonLayoutRows[fromRow].remove(buttonId);
              // Add to new row
              _buttonLayoutRows[rowIndex].add(buttonId);
            });
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHovering ? Colors.blue : Colors.grey.shade300,
                  width: isHovering ? 2 : 1,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 50),
              child: Row(
                children: [
                  Text(
                    'Row ${rowIndex + 1}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _buttonLayoutRows[rowIndex].map((buttonId) {
                        return Draggable<Map<String, dynamic>>(
                          data: {'row': rowIndex, 'button': buttonId},
                          feedback: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: buttonColors[buttonId] ?? Colors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                buttonLabels[buttonId] ?? buttonId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: Chip(
                              label: Text(
                                buttonLabels[buttonId] ?? buttonId,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: buttonColors[buttonId]
                                  ?.withOpacity(0.3),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          child: Chip(
                            label: Text(
                              buttonLabels[buttonId] ?? buttonId,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: buttonColors[buttonId],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
