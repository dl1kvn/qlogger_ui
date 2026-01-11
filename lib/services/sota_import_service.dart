import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/sota_summit_model.dart';
import '../data/database/database_helper.dart';

String _unquote(String value) {
  if (value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

List<String> _parseCsvLine(String line) {
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

/// Parses SOTA CSV data in isolate
/// CSV format: SummitCode,AssociationName,RegionName,SummitName,AltM,AltFt,
/// GridRef1,GridRef2,Longitude,Latitude,Points,BonusPoints,ValidFrom,ValidTo,
/// ActivationCount,ActivationDate,ActivationCall
List<SotaSummitModel> _parseSotaData(String body) {
  final lines = body.split('\n');
  if (lines.isEmpty) {
    return [];
  }

  final summits = <SotaSummitModel>[];

  // Skip header line, parse remaining lines
  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final fields = _parseCsvLine(line);
    if (fields.length < 15) continue;

    try {
      final summitCode = _unquote(fields[0]);
      if (summitCode.isEmpty) continue;

      summits.add(SotaSummitModel(
        summitCode: summitCode,
        associationName: _unquote(fields[1]),
        regionName: _unquote(fields[2]),
        summitName: _unquote(fields[3]),
        altM: int.tryParse(_unquote(fields[4])) ?? 0,
        altFt: int.tryParse(_unquote(fields[5])) ?? 0,
        gridRef1: _unquote(fields[6]).isNotEmpty ? _unquote(fields[6]) : null,
        gridRef2: _unquote(fields[7]).isNotEmpty ? _unquote(fields[7]) : null,
        longitude: double.tryParse(_unquote(fields[8])),
        latitude: double.tryParse(_unquote(fields[9])),
        points: int.tryParse(_unquote(fields[10])) ?? 0,
        bonusPoints: int.tryParse(_unquote(fields[11])) ?? 0,
        validFrom: _unquote(fields[12]).isNotEmpty ? _unquote(fields[12]) : null,
        validTo: _unquote(fields[13]).isNotEmpty ? _unquote(fields[13]) : null,
        activationCount: int.tryParse(_unquote(fields[14])) ?? 0,
        activationDate: fields.length > 15 && _unquote(fields[15]).isNotEmpty
            ? _unquote(fields[15])
            : null,
        activationCall: fields.length > 16 && _unquote(fields[16]).isNotEmpty
            ? _unquote(fields[16])
            : null,
      ));
    } catch (e) {
      // Skip malformed lines
      continue;
    }
  }

  return summits;
}

class SotaImportService {
  static const String _url = 'https://storage.sota.org.uk/summitslist.csv';

  static Future<int> importSotaData() async {
    final response = await http.get(Uri.parse(_url))
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw Exception('Failed to download SOTA data: ${response.statusCode}');
    }

    // Decode as UTF-8 to properly handle umlauts and special characters
    final body = utf8.decode(response.bodyBytes);
    if (body.isEmpty) {
      throw Exception('Empty CSV file');
    }

    // Parse CSV in isolate to avoid blocking UI
    final summits = await compute(_parseSotaData, body);

    // Save to database
    final db = DatabaseHelper();

    // Clear existing data
    await db.deleteAllSotaSummits();

    // Insert new data in batches to avoid memory issues
    const batchSize = 1000;
    for (int i = 0; i < summits.length; i += batchSize) {
      final end = (i + batchSize < summits.length) ? i + batchSize : summits.length;
      await db.insertSotaSummits(summits.sublist(i, end));
    }

    return summits.length;
  }

  static Future<int> getSummitCount() async {
    final db = DatabaseHelper();
    return await db.getSotaSummitCount();
  }
}
