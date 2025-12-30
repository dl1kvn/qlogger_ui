import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/database/database_helper.dart';
import '../data/models/pota_park_model.dart';
import '../services/pota_import_service.dart';

class PotaReferencesScreen extends StatefulWidget {
  final bool selectMode;

  const PotaReferencesScreen({super.key, this.selectMode = false});

  @override
  State<PotaReferencesScreen> createState() => _PotaReferencesScreenState();
}

class _PotaReferencesScreenState extends State<PotaReferencesScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<PotaParkModel> _filteredParks = [];
  bool _isLoading = true;
  int _parkCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _parkCount = await _db.getPotaParkCount();
    _filteredParks = [];
    setState(() => _isLoading = false);
  }

  Future<void> _searchParks(String query) async {
    if (query.length < 2) {
      setState(() => _filteredParks = []);
      return;
    }

    final results = await _db.searchPotaParks(query);
    setState(() => _filteredParks = results);
  }

  Future<void> _importPota() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importing POTA data...'),
          ],
        ),
      ),
    );

    try {
      final count = await PotaImportService.importPotaData();
      Navigator.pop(context);
      Get.snackbar(
        'Import Complete',
        'Imported $count parks',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _loadData();
    } catch (e) {
      Navigator.pop(context);
      Get.snackbar(
        'Import Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Select POTA Reference' : 'POTA References'),
        actions: [
          IconButton(
            onPressed: _importPota,
            icon: const Icon(Icons.download),
            tooltip: 'Import POTA',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  '$_parkCount parks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_parkCount == 0)
                  TextButton.icon(
                    onPressed: _importPota,
                    icon: const Icon(Icons.download),
                    label: const Text('Import POTA'),
                  ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by reference, name or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchParks('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: _searchParks,
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredParks.isEmpty
                    ? Center(
                        child: Text(
                          _parkCount == 0
                              ? 'No POTA data. Tap Import to download.'
                              : _searchController.text.length < 2
                                  ? 'Type at least 2 characters to search'
                                  : 'No results found',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredParks.length,
                        itemBuilder: (context, index) {
                          final park = _filteredParks[index];
                          return ListTile(
                            title: Text(park.reference),
                            subtitle: Text(
                              '${park.name}${park.locationDesc != null ? ' (${park.locationDesc})' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: widget.selectMode
                                ? const Icon(Icons.check)
                                : null,
                            dense: true,
                            onTap: () {
                              if (widget.selectMode) {
                                Get.back(result: park.reference);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
