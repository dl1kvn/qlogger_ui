import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/export_setting_model.dart';

class ExportSettingEditScreen extends StatefulWidget {
  final ExportSettingModel? setting;

  const ExportSettingEditScreen({super.key, this.setting});

  @override
  State<ExportSettingEditScreen> createState() => _ExportSettingEditScreenState();
}

class _ExportSettingEditScreenState extends State<ExportSettingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedFormat = 'adif';
  String _selectedDateFormat = 'YYYYMMDD';
  String _selectedBandFormat = 'band';
  List<String> _selectedFields = [];

  bool get isEditing => widget.setting != null;

  @override
  void initState() {
    super.initState();
    if (widget.setting != null) {
      _nameController.text = widget.setting!.name;
      _selectedFormat = widget.setting!.format;
      _selectedDateFormat = widget.setting!.dateFormat;
      _selectedBandFormat = widget.setting!.bandFormat;
      _selectedFields = List.from(widget.setting!.fieldsList);
    } else {
      // Default fields for new setting
      _selectedFields = ['callsign', 'qsodate', 'qsotime', 'band', 'mymode', 'rstout', 'rstin'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final dbController = Get.find<DatabaseController>();
    final setting = ExportSettingModel(
      id: widget.setting?.id,
      name: _nameController.text.trim(),
      format: _selectedFormat,
      dateFormat: _selectedDateFormat,
      bandFormat: _selectedBandFormat,
    );
    setting.fieldsList = _selectedFields;

    bool success;
    if (isEditing) {
      success = await dbController.updateExportSetting(setting);
    } else {
      success = await dbController.addExportSetting(setting);
    }

    if (success) {
      Get.back();
    } else {
      Get.snackbar(
        'Error',
        dbController.error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _toggleField(String field) {
    setState(() {
      if (_selectedFields.contains(field)) {
        _selectedFields.remove(field);
      } else {
        _selectedFields.add(field);
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedFields.removeAt(oldIndex);
      _selectedFields.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fields not selected (available to add)
    final unselectedFields = ExportSettingModel.allFields
        .where((f) => !_selectedFields.contains(f))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Export Setting' : 'New Export Setting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., ADIF Standard Export',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Format dropdown
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
              ),
              items: ExportSettingModel.formats.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedFormat = v);
              },
            ),
            const SizedBox(height: 16),

            // Date format dropdown
            DropdownButtonFormField<String>(
              value: _selectedDateFormat,
              decoration: const InputDecoration(
                labelText: 'Date Format',
                border: OutlineInputBorder(),
              ),
              items: ExportSettingModel.dateFormats.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedDateFormat = v);
              },
            ),
            const SizedBox(height: 16),

            // Band format dropdown
            DropdownButtonFormField<String>(
              value: _selectedBandFormat,
              decoration: const InputDecoration(
                labelText: 'Band Format',
                border: OutlineInputBorder(),
              ),
              items: ExportSettingModel.bandFormats.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(f == 'band' ? 'Band (20M)' : 'Frequency (14000)'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedBandFormat = v);
              },
            ),
            const SizedBox(height: 24),

            // Selected fields section
            Text(
              'Selected Fields (drag to reorder)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedFields.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No fields selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFields.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final field = _selectedFields[index];
                        return ListTile(
                          key: Key(field),
                          leading: Checkbox(
                            value: true,
                            onChanged: (_) => _toggleField(field),
                          ),
                          title: Text(field),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Available fields section
            if (unselectedFields.isNotEmpty) ...[
              Text(
                'Available Fields',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unselectedFields.length,
                  itemBuilder: (context, index) {
                    final field = unselectedFields[index];
                    return ListTile(
                      leading: Checkbox(
                        value: false,
                        onChanged: (_) => _toggleField(field),
                      ),
                      title: Text(
                        field,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
