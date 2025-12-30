import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/database/database_helper.dart';
import '../data/models/iota_group_model.dart';
import '../data/models/iota_island_model.dart';
import '../services/iota_import_service.dart';

class IotaReferencesScreen extends StatefulWidget {
  final bool selectMode;

  const IotaReferencesScreen({super.key, this.selectMode = false});

  @override
  State<IotaReferencesScreen> createState() => _IotaReferencesScreenState();
}

class _IotaReferencesScreenState extends State<IotaReferencesScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<IotaGroupModel> _allGroups = [];
  List<IotaGroupModel> _filteredGroups = [];
  List<IotaIslandModel> _allIslands = [];
  Map<String, List<String>> _groupIslandNames = {};
  bool _isLoading = true;
  int _groupCount = 0;
  int _islandCount = 0;

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
    _allGroups = await _db.getAllIotaGroups();
    _allIslands = await _db.getAllIotaIslands();
    _groupCount = _allGroups.length;
    _islandCount = _allIslands.length;

    // Build map of group ref to island names for search
    _groupIslandNames = {};
    for (final island in _allIslands) {
      _groupIslandNames.putIfAbsent(island.groupRef, () => []);
      _groupIslandNames[island.groupRef]!.add(island.name.toLowerCase());
    }

    _filteredGroups = _allGroups;
    setState(() => _isLoading = false);
  }

  void _filterGroups(String query) {
    if (query.isEmpty) {
      setState(() => _filteredGroups = _allGroups);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredGroups = _allGroups.where((group) {
        // Search by ref
        if (group.ref.toLowerCase().contains(lowerQuery)) return true;
        // Search by group name
        if (group.name.toLowerCase().contains(lowerQuery)) return true;
        // Search by island names
        final islandNames = _groupIslandNames[group.ref] ?? [];
        return islandNames.any((name) => name.contains(lowerQuery));
      }).toList();
    });
  }

  void _showIslands(IotaGroupModel group) {
    final islands = _allIslands.where((i) => i.groupRef == group.ref).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.ref,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${islands.length} islands',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: islands.isEmpty
                  ? const Center(child: Text('No islands'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: islands.length,
                      itemBuilder: (ctx, index) {
                        final island = islands[index];
                        return ListTile(
                          title: Text(island.name),
                          dense: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importIota() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importing IOTA data...'),
          ],
        ),
      ),
    );

    try {
      final (groups, islands) = await IotaImportService.importIotaData();
      Navigator.pop(context);
      Get.snackbar(
        'Import Complete',
        'Imported $groups groups and $islands islands',
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
        title: Text(widget.selectMode ? 'Select IOTA Reference' : 'IOTA References'),
        actions: [
          IconButton(
            onPressed: _importIota,
            icon: const Icon(Icons.download),
            tooltip: 'Import IOTA',
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
                  '$_groupCount groups, $_islandCount islands',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_groupCount == 0)
                  TextButton.icon(
                    onPressed: _importIota,
                    icon: const Icon(Icons.download),
                    label: const Text('Import IOTA'),
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
                hintText: 'Search by ref, group or island name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterGroups('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: _filterGroups,
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGroups.isEmpty
                    ? Center(
                        child: Text(
                          _allGroups.isEmpty
                              ? 'No IOTA data. Tap Import to download.'
                              : 'No results found',
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = _filteredGroups[index];
                          return ListTile(
                            title: Text(group.ref),
                            subtitle: Text(group.name),
                            trailing: widget.selectMode
                                ? const Icon(Icons.check)
                                : const Icon(Icons.chevron_right),
                            dense: true,
                            onTap: () {
                              if (widget.selectMode) {
                                Get.back(result: group.ref);
                              } else {
                                _showIslands(group);
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
