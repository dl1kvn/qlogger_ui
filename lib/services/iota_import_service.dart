import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/iota_group_model.dart';
import '../data/models/iota_island_model.dart';
import '../data/database/database_helper.dart';

/// Parses IOTA JSON data in isolate
(List<IotaGroupModel>, List<IotaIslandModel>) _parseIotaData(String body) {
  final jsonData = jsonDecode(body) as List<dynamic>;

  final groups = <IotaGroupModel>[];
  final islands = <IotaIslandModel>[];

  for (final item in jsonData) {
    final refno = item['refno'] as String? ?? '';
    final name = item['name'] as String? ?? '';
    final dxccNum = item['dxcc_num'] as String?;

    // Extract continent from ref (e.g., EU-095 -> EU)
    final continent = refno.contains('-') ? refno.split('-')[0] : '';

    // Calculate center lat/lon from min/max
    final latMax = double.tryParse(item['latitude_max']?.toString() ?? '');
    final latMin = double.tryParse(item['latitude_min']?.toString() ?? '');
    final lonMax = double.tryParse(item['longitude_max']?.toString() ?? '');
    final lonMin = double.tryParse(item['longitude_min']?.toString() ?? '');

    double? centerLat;
    double? centerLon;
    if (latMax != null && latMin != null) {
      centerLat = (latMax + latMin) / 2;
    }
    if (lonMax != null && lonMin != null) {
      centerLon = (lonMax + lonMin) / 2;
    }

    // Create group
    groups.add(IotaGroupModel(
      ref: refno,
      name: name,
      continent: continent,
      dxcc: dxccNum,
    ));

    // Process sub_groups and islands
    final subGroups = item['sub_groups'] as List<dynamic>? ?? [];
    for (final subGroup in subGroups) {
      final subref = subGroup['subref'] as String?;
      final status = subGroup['status'] as String? ?? 'Active';
      final isActive = status == 'Active';

      final islandsList = subGroup['islands'] as List<dynamic>? ?? [];
      for (final island in islandsList) {
        final islandName = island['island_name'] as String? ?? '';
        final excluded = island['excluded']?.toString() == '1';

        if (!excluded && islandName.isNotEmpty) {
          islands.add(IotaIslandModel(
            groupRef: refno,
            subgroupRef: subref != '$refno-0-0' ? subref : null,
            name: islandName,
            lat: centerLat,
            lon: centerLon,
            active: isActive,
          ));
        }
      }
    }
  }

  return (groups, islands);
}

class IotaImportService {
  static const String _url =
      'https://www.iota-world.org/islands-on-the-air/downloads/download-file.html?path=fulllist.json';

  static Future<(int, int)> importIotaData() async {
    final response = await http.get(Uri.parse(_url))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Failed to download IOTA data: ${response.statusCode}');
    }

    // Parse JSON in isolate to avoid blocking UI
    final (groups, islands) = await compute(_parseIotaData, response.body);

    // Save to database
    final db = DatabaseHelper();

    // Clear existing data
    await db.deleteAllIotaIslands();
    await db.deleteAllIotaGroups();

    // Insert new data
    await db.insertIotaGroups(groups);
    await db.insertIotaIslands(islands);

    return (groups.length, islands.length);
  }
}
