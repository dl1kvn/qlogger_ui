import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';
import 'activation_edit_screen.dart';
import 'activation_detail_screen.dart';
import 'iota_references_screen.dart';
import 'log_entry_screen.dart';
import 'pota_references_screen.dart';

/// Processes image in isolate - resizes to max 200px and encodes as PNG
Future<Uint8List?> _processActivationImage(Uint8List bytes) async {
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  img.Image resized;
  if (image.width > image.height) {
    resized = img.copyResize(image, width: 200);
  } else {
    resized = img.copyResize(image, height: 200);
  }

  return Uint8List.fromList(img.encodePng(resized));
}

const _activationUrls = {
  'pota': 'https://pota.app/#/map',
  'iota': 'https://www.iota-world.org/',
  'gma': 'https://www.cqgma.org/',
  'sota': 'https://sotl.as/map',
  'cota': 'https://www.cotagroup.org/cotagroup/',
  'lighthouse': 'https://illw.net/',
};

class ActivationsScreen extends StatelessWidget {
  const ActivationsScreen({super.key});

  void _showAddActivationDialog(BuildContext context) {
    final dbController = Get.find<DatabaseController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Choose Activation Type',
          style: TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ActivationModel.activationTypes.map((type) {
              final url = _activationUrls[type];
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _showReferenceDialog(context, type, dbController);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Icon(
                            ActivationModel.getIcon(type),
                            color: ActivationModel.getColor(type),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (url != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              url,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReferenceDialog(
    BuildContext context,
    String type,
    DatabaseController dbController,
  ) async {
    // For IOTA, navigate to IOTA ref picker
    if (type == 'iota') {
      final selectedRef = await Get.to<String>(
        () => const IotaReferencesScreen(selectMode: true),
      );
      if (selectedRef != null && selectedRef.isNotEmpty) {
        final activation = ActivationModel(type: type, reference: selectedRef);
        final success = await dbController.addActivation(activation);
        if (success) {
          final newActivation = dbController.activationList.last;
          Get.to(() => ActivationEditScreen(activation: newActivation));
        }
      }
      return;
    }

    // For POTA, navigate to POTA ref picker
    if (type == 'pota') {
      final selectedRef = await Get.to<String>(
        () => const PotaReferencesScreen(selectMode: true),
      );
      if (selectedRef != null && selectedRef.isNotEmpty) {
        final activation = ActivationModel(type: type, reference: selectedRef);
        final success = await dbController.addActivation(activation);
        if (success) {
          final newActivation = dbController.activationList.last;
          Get.to(() => ActivationEditScreen(activation: newActivation));
        }
      }
      return;
    }

    // For other types, show text input dialog
    final referenceController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final contestIdController = TextEditingController();
    String? imagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              allowMultiple: false,
            );

            if (result != null && result.files.single.path != null) {
              final sourcePath = result.files.single.path!;
              final appDir = await getApplicationDocumentsDirectory();
              final fileName =
                  'activation_${DateTime.now().millisecondsSinceEpoch}.png';
              final destPath = p.join(appDir.path, fileName);

              final bytes = await File(sourcePath).readAsBytes();
              final pngBytes = await compute(_processActivationImage, bytes);

              if (pngBytes != null) {
                final destFile = File(destPath);
                await destFile.writeAsBytes(pngBytes);

                setState(() {
                  imagePath = destFile.path;
                });
              }
            }
          }

          return AlertDialog(
            title: Text(
              '${type.toUpperCase()} Activation',
              style: const TextStyle(fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference',
                      hintText: 'e.g. K-1234',
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (max 25 chars)',
                      hintText: 'e.g. Central Park',
                      counterText: '',
                    ),
                    maxLength: 25,
                    inputFormatters: [LengthLimitingTextInputFormatter(25)],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (max 150 chars)',
                      hintText: 'e.g. Beautiful park in Manhattan',
                    ),
                    maxLength: 150,
                    maxLines: 3,
                    inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contestIdController,
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
                          onPressed: pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(
                            imagePath != null ? 'Change Image' : 'Add Image',
                          ),
                        ),
                      ),
                      if (imagePath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              imagePath = null;
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath!),
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final activation = ActivationModel(
                    type: type,
                    reference: referenceController.text.toUpperCase(),
                    title: titleController.text,
                    description: descriptionController.text,
                    imagePath: imagePath,
                    contestId: contestIdController.text.toUpperCase(),
                  );
                  await dbController.addActivation(activation);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbController = Get.find<DatabaseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Activations')),
      body: Column(
        children: [
          // Reference buttons row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: () => Get.to(() => const IotaReferencesScreen()),
                  icon: const Icon(Icons.beach_access),
                  label: const Text('IOTA REF'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Get.to(() => const PotaReferencesScreen()),
                  icon: const Icon(Icons.park),
                  label: const Text('POTA REF'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Activations list
          Expanded(
            child: Obx(() {
              if (dbController.activationList.isEmpty) {
                return const Center(child: Text('No activations yet'));
              }

              return ListView.builder(
                itemCount: dbController.activationList.length,
                itemBuilder: (context, index) {
                  final activation = dbController.activationList[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First line: icon + reference + image
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              ActivationModel.getIcon(activation.type),
                              color: ActivationModel.getColor(activation.type),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${activation.type.toUpperCase()} ${activation.reference}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (activation.title.isNotEmpty)
                                    Text(
                                      activation.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (activation.imagePath != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => ActivationDetailScreen(
                                      activation: activation,
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(activation.imagePath!),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Second line: icons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                              tooltip: 'View Details',
                              onPressed: () {
                                Get.to(
                                  () => ActivationDetailScreen(
                                    activation: activation,
                                  ),
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit',
                              onPressed: () {
                                Get.to(
                                  () => ActivationEditScreen(
                                    activation: activation,
                                  ),
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.list_alt, size: 20),
                              tooltip: 'View Logs',
                              onPressed: () {
                                Get.to(
                                  () => LogEntryScreen(
                                    initialActivationId: activation.id,
                                  ),
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete',
                              onPressed: () {
                                bool deleteQsos = false;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => StatefulBuilder(
                                    builder: (context, setState) => AlertDialog(
                                      title: const Text(
                                        'Delete Activation',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delete ${activation.type.toUpperCase()} ${activation.reference}?',
                                          ),
                                          const SizedBox(height: 16),
                                          CheckboxListTile(
                                            value: deleteQsos,
                                            onChanged: (value) {
                                              setState(() {
                                                deleteQsos = value ?? false;
                                              });
                                            },
                                            title: const Text(
                                              'Delete all corresponding QSOs?',
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            dense: true,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            if (deleteQsos) {
                                              // Delete all QSOs with this activation_id
                                              final qsosToDelete = dbController
                                                  .qsoList
                                                  .where(
                                                    (q) =>
                                                        q.activationId ==
                                                        activation.id,
                                                  )
                                                  .map((q) => q.id!)
                                                  .toList();
                                              if (qsosToDelete.isNotEmpty) {
                                                await dbController
                                                    .deleteQsosBatch(
                                                      qsosToDelete,
                                                    );
                                              }
                                            }
                                            await dbController.deleteActivation(
                                              activation.id!,
                                            );
                                            Get.back();
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                        // Third line: description
                        if (activation.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            activation.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Fourth line: show in dropdown checkbox
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: activation.showInDropdown,
                                onChanged: (value) async {
                                  final updated = activation.copyWith(
                                    showInDropdown: value ?? true,
                                  );
                                  await dbController.updateActivation(updated);
                                },
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Show in logpage dropdown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
