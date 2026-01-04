import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
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
  late TextEditingController _descriptionController;
  late TextEditingController _contestIdController;
  String? _imagePath;
  final _dbController = Get.find<DatabaseController>();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.activation.type;
    _referenceController = TextEditingController(text: widget.activation.reference);
    _descriptionController = TextEditingController(text: widget.activation.description);
    _contestIdController = TextEditingController(text: widget.activation.contestId);
    _imagePath = widget.activation.imagePath;
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _descriptionController.dispose();
    _contestIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'activation_${widget.activation.id ?? DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final destPath = p.join(appDir.path, fileName);

      // Read and resize image
      final bytes = await File(sourcePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Resize to max 200px while maintaining aspect ratio
        img.Image resized;
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 200);
        } else {
          resized = img.copyResize(image, height: 200);
        }

        // Save as PNG
        final pngBytes = img.encodePng(resized);
        final destFile = File(destPath.replaceAll(p.extension(destPath), '.png'));
        await destFile.writeAsBytes(pngBytes);

        setState(() {
          _imagePath = destFile.path;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    if (_imagePath != null) {
      final file = File(_imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _imagePath = null;
      });
    }
  }

  Future<void> _save() async {
    final updated = widget.activation.copyWith(
      type: _selectedType,
      reference: _referenceController.text.toUpperCase(),
      description: _descriptionController.text,
      imagePath: _imagePath,
      contestId: _contestIdController.text.toUpperCase(),
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
                  child: Row(
                    children: [
                      Icon(ActivationModel.getIcon(type), size: 20, color: ActivationModel.getColor(type)),
                      const SizedBox(width: 8),
                      Text(type.toUpperCase()),
                    ],
                  ),
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
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (max 20 chars)',
                hintText: 'e.g. Central Park',
                counterText: '',
              ),
              maxLength: 20,
              inputFormatters: [
                LengthLimitingTextInputFormatter(20),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contestIdController,
              decoration: const InputDecoration(
                labelText: 'Contest ID',
                hintText: 'e.g. CQWW-CW',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imagePath != null ? 'Change Image' : 'Add Image'),
                  ),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_imagePath!),
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('Image not found'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
