import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/pota_park_model.dart';
import '../data/database/database_helper.dart';

class PotaImportService {
  static const String _url = 'https://pota.app/all_parks_ext.csv';

  static Future<int> importPotaData() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('Failed to download POTA data: ${response.statusCode}');
    }

    // Decode as UTF-8 to properly handle umlauts and special characters
    final body = utf8.decode(response.bodyBytes);
    final lines = body.split('\n');
    if (lines.isEmpty) {
      throw Exception('Empty CSV file');
    }

    final parks = <PotaParkModel>[];

    // Skip header line, parse remaining lines
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _parseCsvLine(line);
      if (fields.length < 8) continue;

      final reference = _unquote(fields[0]);
      final name = _unquote(fields[1]);
      final active = _unquote(fields[2]) == '1';
      final entityId = int.tryParse(_unquote(fields[3]));
      final locationDesc = _unquote(fields[4]);
      final latitude = double.tryParse(_unquote(fields[5]));
      final longitude = double.tryParse(_unquote(fields[6]));
      final grid = _unquote(fields[7]);

      if (reference.isNotEmpty) {
        parks.add(PotaParkModel(
          reference: reference,
          name: name,
          active: active,
          entityId: entityId,
          locationDesc: locationDesc.isNotEmpty ? locationDesc : null,
          latitude: latitude,
          longitude: longitude,
          grid: grid.isNotEmpty ? grid : null,
        ));
      }
    }

    // Save to database
    final db = DatabaseHelper();

    // Clear existing data
    await db.deleteAllPotaParks();

    // Insert new data
    await db.insertPotaParks(parks);

    return parks.length;
  }

  static String _unquote(String value) {
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    fields.add(buffer.toString());
    return fields;
  }
}
