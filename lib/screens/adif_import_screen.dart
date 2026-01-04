import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';
import '../services/adif_import_service.dart';

class AdifImportScreen extends StatefulWidget {
  final List<AdifRecord> records;
  final List<String> adifFields;

  const AdifImportScreen({
    super.key,
    required this.records,
    required this.adifFields,
  });

  @override
  State<AdifImportScreen> createState() => _AdifImportScreenState();
}

class _AdifImportScreenState extends State<AdifImportScreen> {
  final _dbController = Get.find<DatabaseController>();

  // Field mapping: qloggerField -> adifField (null = not mapped)
  late Map<String, String?> _fieldMapping;
  // Which ADIF fields are enabled for import
  late Map<String, bool> _adifFieldEnabled;

  String? _selectedCallsign;
  int? _selectedActivationId;

  @override
  void initState() {
    super.initState();
    _initFieldMapping();

    // Set default callsign
    if (_dbController.callsignList.isNotEmpty) {
      _selectedCallsign = _dbController.callsignList.first.callsign;
    }
  }

  void _initFieldMapping() {
    _fieldMapping = {};
    _adifFieldEnabled = {};

    // Initialize all ADIF fields as enabled
    for (final field in widget.adifFields) {
      _adifFieldEnabled[field] = true;
    }

    // Try to auto-map based on standard mapping
    for (final qloggerField in AdifImportService.qloggerFields) {
      String? matchedAdif;

      // Find matching ADIF field from standard mapping
      for (final entry in AdifImportService.standardMapping.entries) {
        if (entry.value == qloggerField &&
            widget.adifFields.contains(entry.key)) {
          matchedAdif = entry.key;
          break;
        }
      }

      _fieldMapping[qloggerField] = matchedAdif;
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All QSOs?'),
        content: Text(
          'This will permanently delete all ${_dbController.qsoList.length} QSOs from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbController.deleteAllQsos();
      Get.snackbar(
        'Deleted',
        'All QSOs have been deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  List<String> _getMissingRequiredFields() {
    final missing = <String>[];
    for (final reqField in AdifImportService.requiredQloggerFields) {
      final mappedAdif = _fieldMapping[reqField];
      if (mappedAdif == null || _adifFieldEnabled[mappedAdif] != true) {
        missing.add(AdifImportService.qloggerFieldNames[reqField] ?? reqField);
      }
    }
    return missing;
  }

  Future<void> _doImport() async {
    if (_selectedCallsign == null) {
      Get.snackbar(
        'Error',
        'Please select a callsign',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Check required fields
    final missingFields = _getMissingRequiredFields();
    if (missingFields.isNotEmpty) {
      Get.snackbar(
        'Missing Required Fields',
        'Please map: ${missingFields.join(', ')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Build reverse mapping: adifField -> qloggerField (only enabled fields)
    final reverseMapping = <String, String?>{};
    for (final entry in _fieldMapping.entries) {
      final qloggerField = entry.key;
      final adifField = entry.value;
      if (adifField != null && _adifFieldEnabled[adifField] == true) {
        reverseMapping[adifField] = qloggerField;
      }
    }

    // Filter records by STATION_CALLSIGN matching selected callsign
    final filteredRecords = widget.records.where((record) {
      final stationCall = record.get('STATION_CALLSIGN');
      // If no STATION_CALLSIGN in record, include it
      if (stationCall.isEmpty) return true;
      // Otherwise, must match selected callsign (case-insensitive)
      return stationCall.toUpperCase() == _selectedCallsign!.toUpperCase();
    }).toList();

    // Get contestId from selected activation
    String contestId = '';
    if (_selectedActivationId != null) {
      final activation = _dbController.activationList
          .firstWhereOrNull((a) => a.id == _selectedActivationId);
      if (activation != null) {
        contestId = activation.contestId;
      }
    }

    // Convert records to QSOs
    final allQsos = AdifImportService.convertToQsos(
      filteredRecords,
      reverseMapping,
      _selectedCallsign!,
      _selectedActivationId,
      contestId: contestId,
    );

    // Filter out duplicates (compare callsign, mode, time, band)
    final existingQsos = _dbController.qsoList;
    final qsos = allQsos.where((newQso) {
      return !existingQsos.any((existing) =>
          existing.callsign.toUpperCase() == newQso.callsign.toUpperCase() &&
          existing.mymode.toUpperCase() == newQso.mymode.toUpperCase() &&
          existing.qsotime == newQso.qsotime &&
          existing.band == newQso.band);
    }).toList();

    final skippedByCall = widget.records.length - filteredRecords.length;
    final skippedDuplicates = allQsos.length - qsos.length;

    if (qsos.isEmpty) {
      Get.snackbar(
        'No QSOs to Import',
        skippedDuplicates > 0
            ? 'All ${allQsos.length} QSOs already exist (duplicates)'
            : (skippedByCall > 0
                ? 'No QSOs match callsign $_selectedCallsign ($skippedByCall skipped)'
                : 'No valid QSOs found in file'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Importing ${qsos.length} QSOs...'),
            const SizedBox(height: 8),
            const Text(
              'Large files may take a while',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // Batch import all QSOs at once
      final imported = await _dbController.addQsosBatch(qsos);

      if (mounted) Navigator.pop(context); // Close loading dialog
      Get.back();

      // Build message with skip info
      final skipInfo = <String>[];
      if (skippedByCall > 0) skipInfo.add('$skippedByCall other call');
      if (skippedDuplicates > 0) skipInfo.add('$skippedDuplicates duplicates');

      Get.snackbar(
        'Import Complete',
        skipInfo.isNotEmpty
            ? '$imported QSOs imported (${skipInfo.join(', ')} skipped)'
            : '$imported QSOs imported',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      Get.snackbar(
        'Error',
        'Import failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final callsigns = _dbController.callsignList
        .map((c) => c.callsign)
        .toList();
    final activations = _dbController.activationList;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import ${widget.records.length} QSOs'),
        actions: [
          IconButton(
            onPressed: _confirmDeleteAll,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All',
            color: Colors.red,
          ),
          IconButton(
            onPressed: _doImport,
            icon: const Icon(Icons.save),
            tooltip: 'Import',
            color: Colors.green,
          ),
        ],
      ),
      body: Column(
        children: [
          // Callsign and Activation dropdowns
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                // Callsign dropdown
                Expanded(
                  child: callsigns.isEmpty
                      ? const Text(
                          'No callsigns defined',
                          style: TextStyle(color: Colors.red),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedCallsign,
                          decoration: const InputDecoration(
                            labelText: 'My Callsign',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: callsigns.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCallsign = v),
                        ),
                ),
                const SizedBox(width: 12),
                // Activation dropdown
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedActivationId,
                    decoration: const InputDecoration(
                      labelText: 'Activation',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No activation'),
                      ),
                      ...activations.map((a) {
                        return DropdownMenuItem<int?>(
                          value: a.id,
                          child: Row(
                            children: [
                              Icon(
                                ActivationModel.getIcon(a.type),
                                size: 16,
                                color: ActivationModel.getColor(a.type),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      a.reference,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (a.description.isNotEmpty)
                                      Text(
                                        a.description,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (a.imagePath != null) ...[
                                const SizedBox(width: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.file(
                                    File(a.imagePath!),
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _selectedActivationId = v),
                  ),
                ),
              ],
            ),
          ),

          // Warning info line
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange.shade100,
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import separate - ADIF must be for one call only!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.blue.shade100,
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'QLogger Field',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    'ADIF Field (drag to assign)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Field mapping list
          Expanded(
            child: ListView.builder(
              itemCount: AdifImportService.qloggerFields.length,
              itemBuilder: (context, index) {
                final qloggerField = AdifImportService.qloggerFields[index];
                final mappedAdif = _fieldMapping[qloggerField];
                final displayName =
                    AdifImportService.qloggerFieldNames[qloggerField] ??
                    qloggerField;
                final isRequired = AdifImportService.requiredQloggerFields
                    .contains(qloggerField);
                final isMapped =
                    mappedAdif != null && _adifFieldEnabled[mappedAdif] == true;

                return DragTarget<String>(
                  onAcceptWithDetails: (details) {
                    setState(() {
                      // Remove old mapping for this ADIF field
                      for (final key in _fieldMapping.keys) {
                        if (_fieldMapping[key] == details.data) {
                          _fieldMapping[key] = null;
                        }
                      }
                      // Set new mapping
                      _fieldMapping[qloggerField] = details.data;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        color: isHovering
                            ? Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.5)
                            : (index.isEven
                                  ? Colors.transparent
                                  : Colors.grey.withOpacity(0.1)),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // QLogger field (left)
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isRequired && !isMapped
                                        ? Colors.red
                                        : null,
                                  ),
                                ),
                                if (isRequired)
                                  const Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Mapped ADIF field (right)
                          Expanded(
                            flex: 6,
                            child: mappedAdif != null
                                ? _buildMappedAdifChip(mappedAdif, qloggerField)
                                : Text(
                                    '— not mapped —',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Available ADIF fields (draggable) - 30% height, scrollable
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available ADIF Fields (drag to map):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.adifFields.map((field) {
                    final isMapped = _fieldMapping.values.contains(field);
                    final isEnabled = _adifFieldEnabled[field] ?? false;
                    // If mapped, show disabled chip (not draggable)
                    if (isMapped) {
                      return Chip(
                        label: Text(
                          field,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        backgroundColor: Colors.grey.shade300,
                        visualDensity: VisualDensity.compact,
                      );
                    }
                    // Not mapped - show draggable FilterChip
                    return Draggable<String>(
                      data: field,
                      feedback: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Chip(
                          label: Text(
                            field,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: Chip(
                          label: Text(
                            field,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      child: FilterChip(
                        label: Text(
                          field,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: isEnabled,
                        onSelected: (selected) {
                          setState(() => _adifFieldEnabled[field] = selected);
                        },
                        checkmarkColor: Colors.green,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappedAdifChip(String adifField, String qloggerField) {
    final isEnabled = _adifFieldEnabled[adifField] ?? false;
    return Row(
      children: [
        Checkbox(
          value: isEnabled,
          onChanged: (v) {
            setState(() => _adifFieldEnabled[adifField] = v ?? false);
          },
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Draggable<String>(
            data: adifField,
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Chip(
                label: Text(adifField, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue.shade100,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: Chip(
                label: Text(adifField, style: const TextStyle(fontSize: 11)),
              ),
            ),
            child: Chip(
              label: Text(adifField, style: const TextStyle(fontSize: 11)),
              backgroundColor: isEnabled
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() => _fieldMapping[qloggerField] = null);
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
