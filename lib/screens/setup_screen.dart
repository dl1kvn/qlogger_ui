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

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  Future<void> _pickSplashImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'splash_bg${p.extension(sourcePath)}';
      final destPath = p.join(appDir.path, fileName);

      // Copy file to app documents
      await File(sourcePath).copy(destPath);

      // Store path
      final storage = GetStorage();
      await storage.write('splash_bg_path', destPath);

      Get.snackbar(
        'Success',
        'Splash background image set',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _removeSplashImage() async {
    final storage = GetStorage();
    final path = storage.read<String>('splash_bg_path');

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await storage.remove('splash_bg_path');

      Get.snackbar(
        'Success',
        'Splash background image removed',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showSplashImageDialog() {
    final storage = GetStorage();
    final currentPath = storage.read<String>('splash_bg_path');

    Get.dialog(
      AlertDialog(
        title: const Text('Splash Background'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPath != null) ...[
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
              const SizedBox(height: 16),
            ] else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No background image set'),
              ),
          ],
        ),
        actions: [
          if (currentPath != null)
            TextButton(
              onPressed: () {
                Get.back();
                _removeSplashImage();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              _pickSplashImage();
            },
            child: const Text('Choose Image'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qlogger – Setup')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Get.to(() => const OnlineLogsScreen()),
                    icon: const Icon(Icons.cloud),
                    label: const Text('Online Logs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Get.to(() => const MyCallsignsScreen()),
                    icon: const Icon(Icons.person),
                    label: const Text('My Callsigns'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Get.to(() => const ActivationsScreen()),
                    icon: const Icon(Icons.terrain),
                    label: const Text('Activations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showSplashImageDialog,
                    icon: const Icon(Icons.image),
                    label: const Text('Splash Image'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
