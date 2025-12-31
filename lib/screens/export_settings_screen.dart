import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/export_setting_model.dart';
import 'export_setting_edit_screen.dart';

class ExportSettingsScreen extends StatelessWidget {
  const ExportSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbController = Get.find<DatabaseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Export Setting',
            onPressed: () => Get.to(() => const ExportSettingEditScreen()),
          ),
        ],
      ),
      body: Obx(() {
        final settings = dbController.exportSettingList;

        if (settings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No export settings yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to create one',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final setting = settings[index];
            return _ExportSettingTile(setting: setting);
          },
        );
      }),
    );
  }
}

class _ExportSettingTile extends StatelessWidget {
  final ExportSettingModel setting;

  const _ExportSettingTile({required this.setting});

  @override
  Widget build(BuildContext context) {
    final dbController = Get.find<DatabaseController>();
    final fieldCount = setting.fieldsList.length;

    return Dismissible(
      key: Key(setting.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Export Setting'),
            content: Text('Delete "${setting.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (setting.id != null) {
          dbController.deleteExportSetting(setting.id!);
        }
      },
      child: ListTile(
        leading: Icon(
          setting.format == 'adif' ? Icons.description : Icons.table_chart,
          color: setting.format == 'adif' ? Colors.blue : Colors.orange,
        ),
        title: Text(setting.name),
        subtitle: Text(
          '${setting.format.toUpperCase()} • $fieldCount fields • ${setting.dateFormat}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => ExportSettingEditScreen(setting: setting)),
      ),
    );
  }
}
