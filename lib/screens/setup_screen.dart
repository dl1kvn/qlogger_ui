import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'online_logs_screen.dart';
import 'my_callsigns_screen.dart';
import 'activations_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
