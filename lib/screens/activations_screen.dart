import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';
import 'activation_edit_screen.dart';
import 'iota_references_screen.dart';
import 'log_entry_screen.dart';
import 'pota_references_screen.dart';

class ActivationsScreen extends StatelessWidget {
  const ActivationsScreen({super.key});

  void _showAddActivationDialog(BuildContext context) {
    final dbController = Get.find<DatabaseController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Activation Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivationModel.activationTypes.map((type) {
            return ListTile(
              leading: Icon(ActivationModel.getIcon(type), color: ActivationModel.getColor(type)),
              title: Text(type.toUpperCase()),
              onTap: () {
                Navigator.pop(ctx);
                _showReferenceDialog(context, type, dbController);
              },
            );
          }).toList(),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.toUpperCase()} Reference'),
        content: TextField(
          controller: referenceController,
          decoration: const InputDecoration(
            labelText: 'Reference',
            hintText: 'e.g. K-1234',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
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
              );
              final success = await dbController.addActivation(activation);
              if (success) {
                final newActivation = dbController.activationList.last;
                Get.to(() => ActivationEditScreen(activation: newActivation));
              }
            },
            child: const Text('Add'),
          ),
        ],
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
                    title: Text(activation.reference),
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
