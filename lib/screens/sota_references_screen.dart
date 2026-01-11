import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/database/database_helper.dart';
import '../data/models/sota_summit_model.dart';
import '../services/sota_import_service.dart';

class SotaReferencesScreen extends StatefulWidget {
  final bool selectMode;

  const SotaReferencesScreen({super.key, this.selectMode = false});

  @override
  State<SotaReferencesScreen> createState() => _SotaReferencesScreenState();
}

class _SotaReferencesScreenState extends State<SotaReferencesScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<SotaSummitModel> _filteredSummits = [];
  bool _isLoading = true;
  int _summitCount = 0;

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
    _summitCount = await _db.getSotaSummitCount();
    _filteredSummits = [];
    setState(() => _isLoading = false);
  }

  Future<void> _searchSummits(String query) async {
    if (query.length < 2) {
      setState(() => _filteredSummits = []);
      return;
    }

    final results = await _db.searchSotaSummits(query);
    setState(() => _filteredSummits = results);
  }

  Future<void> _importSota() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importing SOTA data...\nThis may take a while.'),
          ],
        ),
      ),
    );

    try {
      final count = await SotaImportService.importSotaData();
      Navigator.pop(context);
      Get.snackbar(
        'Import Complete',
        'Imported $count summits',
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
        title: Text(widget.selectMode ? 'Select SOTA Reference' : 'SOTA References'),
        actions: [
          IconButton(
            onPressed: _importSota,
            icon: const Icon(Icons.download),
            tooltip: 'Import SOTA',
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
                  '$_summitCount summits',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_summitCount == 0)
                  TextButton.icon(
                    onPressed: _importSota,
                    icon: const Icon(Icons.download),
                    label: const Text('Import SOTA'),
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
                hintText: 'Search by code, name, association...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchSummits('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: _searchSummits,
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSummits.isEmpty
                    ? Center(
                        child: Text(
                          _summitCount == 0
                              ? 'No SOTA data. Tap Import to download.'
                              : _searchController.text.length < 2
                                  ? 'Type at least 2 characters to search'
                                  : 'No results found',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSummits.length,
                        itemBuilder: (context, index) {
                          final summit = _filteredSummits[index];
                          return ListTile(
                            title: Text(summit.summitCode),
                            subtitle: Text(
                              '${summit.summitName} (${summit.altM}m, ${summit.points}pts)\n${summit.location}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: widget.selectMode
                                ? const Icon(Icons.check)
                                : Text(
                                    '${summit.points}p',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: summit.points >= 8
                                          ? Colors.red
                                          : summit.points >= 4
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                  ),
                            isThreeLine: true,
                            dense: true,
                            onTap: () {
                              if (widget.selectMode) {
                                Get.back(result: summit.summitCode);
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
