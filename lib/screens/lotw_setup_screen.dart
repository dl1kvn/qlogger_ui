import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class LotwSetupScreen extends StatefulWidget {
  final String callsign;

  const LotwSetupScreen({super.key, required this.callsign});

  @override
  State<LotwSetupScreen> createState() => _LotwSetupScreenState();
}

class LotwSetupResult {
  final String certificate; // Base64-encoded P12 bytes
  final String privateKey;  // P12 password

  LotwSetupResult({required this.certificate, required this.privateKey});
}

class _LotwSetupScreenState extends State<LotwSetupScreen> {
  final _passwordController = TextEditingController();

  String? _fileName;
  Uint8List? _fileBytes;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickP12File() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        // Validate P12 format - must start with ASN.1 SEQUENCE (0x30)
        if (bytes == null || bytes.length < 4 || bytes[0] != 0x30) {
          setState(() {
            _errorMessage = 'Invalid P12 format';
            _fileName = null;
            _fileBytes = null;
          });
          return;
        }

        setState(() {
          _fileName = file.name;
          _fileBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  void _applyAndReturn() {
    if (_fileBytes == null) {
      setState(() {
        _errorMessage = 'Please select a P12 file first';
      });
      return;
    }

    // Store P12 as Base64, password separately
    final base64P12 = base64Encode(_fileBytes!);
    final password = _passwordController.text;

    Get.back(result: LotwSetupResult(
      certificate: base64P12,
      privateKey: password,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoTW Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup LoTW for ${widget.callsign}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Load your .p12 certificate file from ARRL LoTW',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Step 1: Load P12 file
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1: Select P12 File',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickP12File,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Load P12 File'),
                          ),
                        ),
                      ],
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fileBytes!.length} bytes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Enter password
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 2: Enter Password',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'P12 Password',
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty if no password',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _fileBytes != null ? _applyAndReturn : null,
                icon: const Icon(Icons.check),
                label: const Text('Eintragen'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
