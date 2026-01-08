import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/qso_form_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/database_controller.dart';
import '../data/models/satellite_model.dart';
import '../data/satellites.dart';

class SatelliteSetupScreen extends StatelessWidget {
  const SatelliteSetupScreen({super.key});

  void _goToStartPage() {
    final nav = Get.find<NavigationController>();
    nav.changePage(0);
    Get.back();
  }

  void _showSatelliteDialog({SatelliteModel? satellite}) {
    final dbController = Get.find<DatabaseController>();
    final nameController = TextEditingController(text: satellite?.name ?? '');
    final descController = TextEditingController(
      text: satellite?.description ?? '',
    );
    final isEditing = satellite != null;

    Get.dialog(
      AlertDialog(
        title: Text(
          isEditing ? 'Edit Satellite' : 'Add Satellite',
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. QO-100',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Qatar-OSCAR 100',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Name is required',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              if (isEditing) {
                dbController.updateSatellite(
                  satellite.copyWith(
                    name: name,
                    description: descController.text.trim(),
                  ),
                );
              } else {
                dbController.addSatellite(
                  SatelliteModel(
                    name: name,
                    description: descController.text.trim(),
                  ),
                );
              }
              Get.back();
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SatelliteModel satellite) {
    final dbController = Get.find<DatabaseController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Satellite', style: TextStyle(fontSize: 16)),
        content: Text('Delete "${satellite.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              dbController.deleteSatellite(satellite.id!);
              Get.back();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _importDefaultSatellites() {
    final dbController = Get.find<DatabaseController>();
    final existingNames = dbController.satelliteList.map((s) => s.name).toSet();
    final maxSortOrder = dbController.satelliteList.isEmpty
        ? 0
        : dbController.satelliteList
              .map((s) => s.sortOrder)
              .reduce((a, b) => a > b ? a : b);

    int imported = 0;
    for (final name in satelliteList) {
      if (name == 'no sat') continue;
      if (existingNames.contains(name)) continue;
      dbController.addSatellite(
        SatelliteModel(name: name, sortOrder: maxSortOrder + imported + 1),
      );
      imported++;
    }

    Get.snackbar(
      'Import Complete',
      '$imported satellites imported',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _onReorder(int oldIndex, int newIndex, List<SatelliteModel> satellites) {
    final dbController = Get.find<DatabaseController>();

    if (newIndex > oldIndex) newIndex--;
    final item = satellites.removeAt(oldIndex);
    satellites.insert(newIndex, item);

    // Update sort order for all items
    for (int i = 0; i < satellites.length; i++) {
      final sat = satellites[i];
      if (sat.sortOrder != i) {
        dbController.updateSatellite(sat.copyWith(sortOrder: i));
      }
    }
  }

  void _toggleActive(SatelliteModel satellite) async {
    final dbController = Get.find<DatabaseController>();
    final newIsActive = !satellite.isActive;

    if (!newIsActive) {
      // Unchecking: move to end of list
      final maxSortOrder = dbController.satelliteList.isEmpty
          ? 0
          : dbController.satelliteList
                .map((s) => s.sortOrder)
                .reduce((a, b) => a > b ? a : b);
      await dbController.updateSatellite(
        satellite.copyWith(isActive: false, sortOrder: maxSortOrder + 1),
      );
    } else {
      // Checking: just toggle, keep position
      await dbController.updateSatellite(satellite.copyWith(isActive: true));
    }
    // Reload to apply DB sorting
    await dbController.loadSatellites();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<QsoFormController>();
    final dbController = Get.find<DatabaseController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToStartPage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Satellite Setup'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToStartPage,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Import default satellites',
              onPressed: _importDefaultSatellites,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showSatelliteDialog(),
          child: const Icon(Icons.add),
        ),
        body: Obx(() {
          final satellites = dbController.satelliteList.toList();
          return CustomScrollView(
            slivers: [
              // Help accordion
              SliverToBoxAdapter(
                child: ExpansionTile(
                  title: const Text('Help'),
                  leading: const Icon(Icons.help_outline),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        children: const [
                          TextSpan(
                            text: 'LoTW and Satellite Names\n\n',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text:
                                'Logbook of The World (LoTW) is the ARRL\'s official QSO confirmation system.\n'
                                'For satellite QSOs, LoTW requires:\n\n'
                                '• PROP_MODE=SAT\n'
                                '• SAT_NAME=<satellite name>\n\n'
                                'The satellite name must be recognized by LoTW. There is no public API or official downloadable list of accepted satellite names.\n\n'
                                'A satellite is considered verified if the LoTW upload succeeds using its SAT_NAME.\n\n',
                          ),
                          TextSpan(
                            text: 'How to find the current satellite list\n\n',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text:
                                '1. Update TQSL to the latest version.\n'
                                '2. Select "Create a new ADIF file" in TQSL.\n'
                                '3. During the ADIF creation process, open the Satellite selection.\n'
                                '4. The satellites shown there represent the currently accepted LoTW satellite names.\n\n'
                                'Use these names directly as SAT_NAME values in your log.\n\n'
                                'Most logging applications use a static list based on this TQSL satellite selection and update it manually when needed.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              // Show satellite dropdown toggle
              SliverToBoxAdapter(
                child: CheckboxListTile(
                  title: const Text('Show Satellite Dropdown'),
                  subtitle: const Text(
                    'Display satellite selection in QSO form',
                  ),
                  value: c.showSatellite.value,
                  onChanged: (_) => c.toggleShowSatellite(),
                ),
              ),
              const SliverToBoxAdapter(child: Divider()),
              // Satellite list
              if (satellites.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No satellites added yet')),
                )
              else
                SliverReorderableList(
                  itemCount: satellites.length,
                  onReorder: (oldIndex, newIndex) =>
                      _onReorder(oldIndex, newIndex, satellites),
                  itemBuilder: (context, index) {
                    final sat = satellites[index];
                    return Material(
                      key: ValueKey(sat.id),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            Checkbox(
                              value: sat.isActive,
                              onChanged: (_) => _toggleActive(sat),
                            ),
                          ],
                        ),
                        title: Text(
                          sat.name,
                          style: TextStyle(
                            color: sat.isActive ? null : Colors.grey,
                          ),
                        ),
                        subtitle: sat.description.isNotEmpty
                            ? Text(
                                sat.description,
                                style: TextStyle(
                                  color: sat.isActive ? null : Colors.grey,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _showSatelliteDialog(satellite: sat),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _confirmDelete(sat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        }),
      ),
    );
  }
}
