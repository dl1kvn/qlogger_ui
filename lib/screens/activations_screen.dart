import 'dart:io';
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
import 'iota_references_screen.dart';
import 'log_entry_screen.dart';
import 'pota_references_screen.dart';

const _activationUrls = {
  'pota': 'https://pota.app/#/map',
  'iota': 'https://www.iota-world.org/',
  'gma': 'https://www.cqgma.org/',
  'sota': 'https://www.sotadata.org',
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
        title: const Text('Choose Activation Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ActivationModel.activationTypes.map((type) {
              final url = _activationUrls[type];
              return ListTile(
                leading: Icon(ActivationModel.getIcon(type), color: ActivationModel.getColor(type)),
                title: Text(type.toUpperCase()),
                subtitle: url != null
                    ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                        child: Text(
                          url,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _showReferenceDialog(context, type, dbController);
                },
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

  void _showReferenceDialog(BuildContext context, String type, DatabaseController dbController) async {
    // For IOTA, navigate to IOTA ref picker
    if (type == 'iota') {
      final selectedRef = await Get.to<String>(() => const IotaReferencesScreen(selectMode: true));
      if (selectedRef != null && selectedRef.isNotEmpty) {
        final activation = ActivationModel(
          type: type,
          reference: selectedRef,
        );
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
      final selectedRef = await Get.to<String>(() => const PotaReferencesScreen(selectMode: true));
      if (selectedRef != null && selectedRef.isNotEmpty) {
        final activation = ActivationModel(
          type: type,
          reference: selectedRef,
        );
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
              final fileName = 'activation_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
              final destPath = p.join(appDir.path, fileName);

              final bytes = await File(sourcePath).readAsBytes();
              final image = img.decodeImage(bytes);

              if (image != null) {
                img.Image resized;
                if (image.width > image.height) {
                  resized = img.copyResize(image, width: 200);
                } else {
                  resized = img.copyResize(image, height: 200);
                }

                final pngBytes = img.encodePng(resized);
                final destFile = File(destPath.replaceAll(p.extension(destPath), '.png'));
                await destFile.writeAsBytes(pngBytes);

                setState(() {
                  imagePath = destFile.path;
                });
              }
            }
          }

          return AlertDialog(
            title: Text('${type.toUpperCase()} Activation'),
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
                    controller: descriptionController,
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
                          label: Text(imagePath != null ? 'Change Image' : 'Add Image'),
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
      appBar: AppBar(
        title: const Text('Activations'),
      ),
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
                return const Center(
                  child: Text('No activations yet'),
                );
              }

              return ListView.builder(
                itemCount: dbController.activationList.length,
                itemBuilder: (context, index) {
                  final activation = dbController.activationList[index];
                  return ListTile(
                    leading: Icon(ActivationModel.getIcon(activation.type), color: ActivationModel.getColor(activation.type)),
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(activation.reference),
                              if (activation.description.isNotEmpty)
                                Text(
                                  activation.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        if (activation.imagePath != null) ...[
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(activation.imagePath!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.list_alt),
                          tooltip: 'View Logs',
                          onPressed: () {
                            Get.to(() => LogEntryScreen(initialActivationId: activation.id));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Activation'),
                                content: Text('Delete ${activation.type.toUpperCase()} activation?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () {
                                      dbController.deleteActivation(activation.id!);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Get.to(() => ActivationEditScreen(activation: activation));
                    },
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
