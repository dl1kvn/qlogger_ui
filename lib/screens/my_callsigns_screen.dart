import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import 'callsign_edit_screen.dart';

class MyCallsignsScreen extends StatelessWidget {
  const MyCallsignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbController = Get.find<DatabaseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Callsigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const CallsignEditScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (dbController.isLoading.value && dbController.callsignList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dbController.callsignList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No callsigns yet'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Get.to(() => const CallsignEditScreen()),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Callsign'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: dbController.callsignList.length,
          itemBuilder: (context, index) {
            final callsign = dbController.callsignList[index];
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(callsign.callsign),
              subtitle: Text(_buildSubtitle(callsign)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => CallsignEditScreen(callsign: callsign)),
            );
          },
        );
      }),
    );
  }

  String _buildSubtitle(callsign) {
    final services = <String>[];
    if (callsign.useclublog == 1) services.add('ClubLog');
    if (callsign.useeqsl == 1) services.add('eQSL');
    if (callsign.uselotw == 1) services.add('LoTW');
    return services.isEmpty ? 'No online services' : services.join(', ');
  }
}
