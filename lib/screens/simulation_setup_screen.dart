import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Global simulation state
final _simulationStorage = GetStorage();
final simulationActive = false.obs; // Always start inactive, not persisted
final simulationPaused = false.obs;
final simulationMinWpm = (_simulationStorage.read<double>('simulation_min_wpm') ?? 20.0).obs;
final simulationMaxWpm = (_simulationStorage.read<double>('simulation_max_wpm') ?? 28.0).obs;
final simulationCqWpm = (_simulationStorage.read<double>('simulation_cq_wpm') ?? 24.0).obs;
final simulationFrequency = (_simulationStorage.read<double>('simulation_frequency') ?? 600.0).obs;
final simulationGeneratedCallsign = ''.obs;
final simulationGeneratedNumber = ''.obs;
final simulationGeneratedCode = ''.obs; // 2 letters + 5 numbers
final simulationAwaitingResponse = false.obs;
final simulationResultList = <SimulationResult>[].obs;
final simulationSaveCount = 0.obs;

class SimulationResult {
  final String actualCallsign;
  final String userCallsign;
  final String actualNumber;
  final String userNumber;
  final String actualCode;
  final String userCode;

  SimulationResult({
    required this.actualCallsign,
    required this.userCallsign,
    required this.actualNumber,
    required this.userNumber,
    required this.actualCode,
    required this.userCode,
  });

  bool get callsignCorrect => actualCallsign.toUpperCase() == userCallsign.toUpperCase();
  bool get numberCorrect => actualNumber == userNumber;
  bool get codeCorrect => actualCode.toUpperCase() == userCode.toUpperCase();
}

class SimulationSetupScreen extends StatelessWidget {
  const SimulationSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulation Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: simulationActive.value ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    simulationActive.value ? Icons.play_circle : Icons.stop_circle,
                    color: simulationActive.value ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    simulationActive.value ? 'Simulation Active' : 'Simulation Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: simulationActive.value ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // My CQ WPM Slider
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My CQ Speed: ${simulationCqWpm.value.round()} WPM',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Speed used when sending CQ and responses',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const SizedBox(height: 16),
            // Answer WPM Range Slider
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer Speed: ${simulationMinWpm.value.round()} - ${simulationMaxWpm.value.round()} WPM',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Random speed range for incoming callsigns',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const SizedBox(height: 16),
            // Tone Frequency Slider
            Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tone Frequency: ${simulationFrequency.value.round()} Hz',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pitch of the CW tone',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Slider(
                  value: simulationFrequency.value,
                  min: 550,
                  max: 800,
                  divisions: 25,
                  label: '${simulationFrequency.value.round()} Hz',
                  onChanged: (value) {
                    simulationFrequency.value = value;
                    _simulationStorage.write('simulation_frequency', value);
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
