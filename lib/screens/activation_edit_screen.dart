import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';

class ActivationEditScreen extends StatefulWidget {
  final ActivationModel activation;

  const ActivationEditScreen({super.key, required this.activation});

  @override
  State<ActivationEditScreen> createState() => _ActivationEditScreenState();
}

class _ActivationEditScreenState extends State<ActivationEditScreen> {
  late String _selectedType;
  late TextEditingController _referenceController;
  final _dbController = Get.find<DatabaseController>();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.activation.type;
    _referenceController = TextEditingController(text: widget.activation.reference);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.activation.copyWith(
      type: _selectedType,
      reference: _referenceController.text.toUpperCase(),
    );
    await _dbController.updateActivation(updated);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Activation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: ActivationModel.activationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference',
                hintText: 'e.g. K-1234',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
    );
  }
}
