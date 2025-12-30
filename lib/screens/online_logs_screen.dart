import 'package:flutter/material.dart';

class OnlineLogsScreen extends StatelessWidget {
  const OnlineLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Logs')),
      body: const Center(
        child: Text('Online Logs'),
      ),
    );
  }
}
