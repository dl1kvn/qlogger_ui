import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'online_logs_screen.dart';
import 'my_callsigns_screen.dart';
import 'activations_screen.dart';
import 'help_screen.dart';
import 'satellite_setup_screen.dart';

// Global simulation state
final _simulationStorage = GetStorage();
final simulationActive = (_simulationStorage.read<bool>('simulation_active') ?? false).obs;
final simulationPaused = false.obs; // Paused state for QSO form toggle
final simulationMinWpm = (_simulationStorage.read<double>('simulation_min_wpm') ?? 20.0).obs;
final simulationMaxWpm = (_simulationStorage.read<double>('simulation_max_wpm') ?? 28.0).obs;
final simulationCqWpm = (_simulationStorage.read<double>('simulation_cq_wpm') ?? 24.0).obs;
final simulationGeneratedCallsign = ''.obs; // The random callsign generated during simulation

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  void _showSplashImageDialog() {
    final storage = GetStorage();
    final savedPath = storage.read<String>('splash_bg_path');
    final previewPath = Rxn<String>(savedPath);
    final pendingSourcePath = Rxn<String>();
    final removeRequested = false.obs;
    final currentText = storage.read<String>('splash_text') ?? '';
    final textController = TextEditingController(text: currentText);

    Future<void> pickImage() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        pendingSourcePath.value = result.files.single.path!;
        previewPath.value = result.files.single.path!;
        removeRequested.value = false;
      }
    }

    void removeImage() {
      previewPath.value = null;
      pendingSourcePath.value = null;
      removeRequested.value = true;
    }

    Future<void> saveChanges() async {
      // Handle image removal
      if (removeRequested.value && savedPath != null) {
        final file = File(savedPath);
        if (await file.exists()) {
          await file.delete();
        }
        await storage.remove('splash_bg_path');
      }

      // Handle new image
      if (pendingSourcePath.value != null) {
        final sourcePath = pendingSourcePath.value!;
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'splash_bg${p.extension(sourcePath)}';
        final destPath = p.join(appDir.path, fileName);

        await File(sourcePath).copy(destPath);
        await storage.write('splash_bg_path', destPath);
      }

      // Save text
      storage.write('splash_text', textController.text);
      Get.back();
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Start Screen'),
        content: Obx(() {
          final currentPath = previewPath.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentPath != null && File(currentPath).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(currentPath),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('Image not found'),
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No background image set'),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (currentPath != null)
                    TextButton(
                      onPressed: removeImage,
                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  FilledButton(
                    onPressed: pickImage,
                    child: const Text('Choose Image'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Splash Text',
                  hintText: 'Built for operators',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: saveChanges,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () => Get.to(() => const MyCallsignsScreen()),
              icon: const Icon(Icons.person),
              label: const Text('My Callsigns'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Get.to(() => const ActivationsScreen()),
              icon: const Icon(Icons.terrain),
              label: const Text('Activations'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Get.to(() => const SatelliteSetupScreen()),
              icon: const Icon(Icons.satellite_alt),
              label: const Text('Satellite Setup'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _showSplashImageDialog,
              icon: const Icon(Icons.image),
              label: const Text('Start Screen'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Get.to(() => const OnlineLogsScreen()),
              icon: const Icon(Icons.cloud),
              label: const Text('Online Logs'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Get.to(() => const HelpScreen()),
              icon: const Icon(Icons.help),
              label: const Text('Help'),
            ),
            const SizedBox(height: 12),
            Obx(() => FilledButton.icon(
              onPressed: () {
                simulationActive.value = !simulationActive.value;
                _simulationStorage.write('simulation_active', simulationActive.value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: simulationActive.value ? Colors.green : Colors.red,
              ),
              icon: Icon(simulationActive.value ? Icons.pause : Icons.play_arrow),
              label: const Text('Simulation'),
            )),
            const SizedBox(height: 12),
            // My CQ WPM Slider
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My CQ Speed: ${simulationCqWpm.value.round()} WPM',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: simulationCqWpm.value,
                  min: 18,
                  max: 38,
                  divisions: 20,
                  label: simulationCqWpm.value.round().toString(),
                  onChanged: (value) {
                    simulationCqWpm.value = value;
                    _simulationStorage.write('simulation_cq_wpm', value);
                  },
                ),
              ],
            )),
            const SizedBox(height: 8),
            // Answer WPM Range Slider
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer Speed: ${simulationMinWpm.value.round()} - ${simulationMaxWpm.value.round()} WPM',
                  style: const TextStyle(fontSize: 14),
                ),
                RangeSlider(
                  values: RangeValues(simulationMinWpm.value, simulationMaxWpm.value),
                  min: 18,
                  max: 38,
                  divisions: 20,
                  labels: RangeLabels(
                    simulationMinWpm.value.round().toString(),
                    simulationMaxWpm.value.round().toString(),
                  ),
                  onChanged: (values) {
                    simulationMinWpm.value = values.start;
                    simulationMaxWpm.value = values.end;
                    _simulationStorage.write('simulation_min_wpm', values.start);
                    _simulationStorage.write('simulation_max_wpm', values.end);
                  },
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
