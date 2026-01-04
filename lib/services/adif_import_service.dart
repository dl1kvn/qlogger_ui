import '../data/models/qso_model.dart';

class AdifRecord {
  final Map<String, String> fields;

  AdifRecord(this.fields);

  String get(String key) => fields[key.toUpperCase()] ?? '';
}

class AdifImportService {
  /// Parse ADIF file content and return list of records
  static List<AdifRecord> parseAdif(String content) {
    final records = <AdifRecord>[];

    // Find end of header
    final headerEnd = content.toUpperCase().indexOf('<EOH>');
    final dataStart = headerEnd >= 0 ? headerEnd + 5 : 0;
    final data = content.substring(dataStart);

    // Split by EOR (end of record)
    final recordStrings = data.split(RegExp(r'<EOR>', caseSensitive: false));

    for (final recordStr in recordStrings) {
      if (recordStr.trim().isEmpty) continue;

      final fields = <String, String>{};
      final fieldPattern = RegExp(r'<(\w+):(\d+)(?::\w+)?>([^<]*)', caseSensitive: false);
      final matches = fieldPattern.allMatches(recordStr);

      for (final match in matches) {
        final fieldName = match.group(1)!.toUpperCase();
        final length = int.tryParse(match.group(2)!) ?? 0;
        var value = match.group(3) ?? '';

        // Trim value to specified length
        if (value.length > length) {
          value = value.substring(0, length);
        }
        value = value.trim();

        if (value.isNotEmpty) {
          fields[fieldName] = value;
        }
      }

      if (fields.isNotEmpty) {
        records.add(AdifRecord(fields));
      }
    }

    return records;
  }

  /// ADIF fields to ignore (not useful for import)
  static const List<String> ignoredAdifFields = [
    'APP_LOTW_MY_DXCC_ENTITY_STATUS',
    'APP_LOTW_MY_CQ_ZONE_INFERRE',
    'APP_LOTW_MY_CQ_ZONE_INFERRED',
    'APP_LOTW_MY_ITU_ZONE_INFERRED',
    'APP_LOTW_RXQSL',
    'APP_LOTW_DXCC_ENTITY_STATUS',
    'APP_LOTW_2XQSL',
    'APP_LOTW_MODEGROUP',
    'APP_LOTW_OWNCALL',
    'APP_LOTW_CQZ_INFERRED',
    'APP_LOTW_ITUZ_INFERRED',
    'APP_LOTW_QSO_TIMESTAMP',
    'APP_LOTW_RXQSO',
    'APP_LOTW_GRIDSQUARE_INVALID',
    'APP_LOTW_CQZ_INVALID',
    'APP_LOTW_ITUZ_INVALID',
    'MY_CQ_ZONE',
    'MY_ITU_ZONE',
    'MY_COUNTRY',
    'MY_DXCC',
    'DXCC',
    'COUNTRY',
    'CNTY',
    'STATE',
    'PFX',
    'CQZ',
    'ITUZ',
    'QSL_RCVD',
    'QSLRDATE',
    'SUBMODE',
    'VUCC_GRIDS',
    'PROP_MODE',
    'BAND_RX',
    'STATION_CALLSIGN', // Used for filtering, not mapping
  ];

  /// Get all unique field names from parsed records (excluding ignored fields)
  static List<String> getFieldNames(List<AdifRecord> records) {
    final fieldSet = <String>{};
    for (final record in records) {
      fieldSet.addAll(record.fields.keys);
    }
    // Remove ignored fields
    fieldSet.removeWhere((f) => ignoredAdifFields.contains(f.toUpperCase()));
    final fields = fieldSet.toList()..sort();
    return fields;
  }

  /// Standard ADIF field to QLogger field mapping
  static const Map<String, String> standardMapping = {
    'CALL': 'callsign',
    'QSO_DATE': 'qsodate',
    'TIME_ON': 'qsotime',
    'BAND': 'band',
    'FREQ': 'band', // Will be converted
    'MODE': 'mymode',
    'RST_SENT': 'rstout',
    'RST_RCVD': 'rstin',
    'GRIDSQUARE': 'gridsquare',
    'SRX_STRING': 'received',
    'STX': 'qsonr',
    'COMMENT': 'xtra',
    'MY_IOTA': 'myiota',
    'MY_SOTA_REF': 'mysota',
    'MY_POTA_REF': 'mypota',
    'DISTANCE': 'distance',
  };

  /// QLogger fields that can be mapped
  static const List<String> qloggerFields = [
    'callsign',
    'qsodate',
    'qsotime',
    'band',
    'mymode',
    'rstout',
    'rstin',
    'received',
    'xtra',
    'qsonr',
    'gridsquare',
    'distance',
    'myiota',
    'mysota',
    'mypota',
  ];

  /// Required ADIF fields for import
  static const List<String> requiredAdifFields = [
    'CALL',
    'QSO_DATE',
    'TIME_ON',
    'FREQ',
    'MODE',
  ];

  /// Required QLogger fields (mapped from ADIF)
  static const List<String> requiredQloggerFields = [
    'callsign',
    'qsodate',
    'qsotime',
    'band',
    'mymode',
  ];

  /// QLogger field display names
  static const Map<String, String> qloggerFieldNames = {
    'callsign': 'Callsign',
    'qsodate': 'Date',
    'qsotime': 'Time',
    'band': 'Band',
    'mymode': 'Mode',
    'rstout': 'RST Sent',
    'rstin': 'RST Rcvd',
    'received': 'NR/Info',
    'xtra': 'Xtra',
    'qsonr': 'QSO Nr',
    'gridsquare': 'Gridsquare',
    'distance': 'Distance',
    'myiota': 'My IOTA',
    'mysota': 'My SOTA',
    'mypota': 'My POTA',
  };

  /// Band conversion from frequency to band
  static const Map<String, String> _freqToBand = {
    '160M': '1.8',
    '80M': '3.5',
    '60M': '5',
    '40M': '7',
    '30M': '10',
    '20M': '14',
    '17M': '18',
    '15M': '21',
    '12M': '24',
    '10M': '28',
    '6M': '50',
    '2M': '144',
    '70CM': '440',
  };

  /// Convert ADIF band value to QLogger format
  static String convertBand(String adifBand) {
    final upper = adifBand.toUpperCase();
    if (_freqToBand.containsKey(upper)) {
      return _freqToBand[upper]!;
    }
    // Try to extract MHz from frequency
    final freq = double.tryParse(adifBand);
    if (freq != null) {
      if (freq < 2) return '1.8';
      if (freq < 4) return '3.5';
      if (freq < 6) return '5';
      if (freq < 8) return '7';
      if (freq < 12) return '10';
      if (freq < 16) return '14';
      if (freq < 20) return '18';
      if (freq < 23) return '21';
      if (freq < 26) return '24';
      if (freq < 35) return '28';
      if (freq < 100) return '50';
      if (freq < 200) return '144';
      return '440';
    }
    return adifBand;
  }

  /// Convert date format from ADIF (YYYYMMDD or YYYY-MM-DD) to QLogger (YYYYMMDD)
  static String convertDate(String adifDate) {
    return adifDate.replaceAll('-', '');
  }

  /// Convert time format to HHMM
  static String convertTime(String adifTime) {
    final cleaned = adifTime.replaceAll(':', '');
    if (cleaned.length >= 4) {
      return cleaned.substring(0, 4);
    }
    return cleaned.padRight(4, '0');
  }

  /// Convert ADIF records to QSO models using field mapping
  static List<QsoModel> convertToQsos(
    List<AdifRecord> records,
    Map<String, String?> fieldMapping, // adifField -> qloggerField
    String myCallsign,
    int? activationId, {
    String contestId = '',
  }) {
    final qsos = <QsoModel>[];

    for (final record in records) {
      final qsoData = <String, String>{};

      for (final entry in fieldMapping.entries) {
        final adifField = entry.key;
        final qloggerField = entry.value;
        if (qloggerField == null) continue;

        var value = record.get(adifField);
        if (value.isEmpty) continue;

        // Convert values based on field type
        if (qloggerField == 'band') {
          value = convertBand(value);
        } else if (qloggerField == 'qsodate') {
          value = convertDate(value);
        } else if (qloggerField == 'qsotime') {
          value = convertTime(value);
        }

        qsoData[qloggerField] = value;
      }

      // Only create QSO if we have at least callsign and date
      if (qsoData['callsign']?.isNotEmpty == true &&
          qsoData['qsodate']?.isNotEmpty == true) {
        // Default RST: 599 for CW, 59 for all other modes
        final mode = qsoData['mymode']?.toUpperCase() ?? '';
        final defaultRst = mode == 'CW' ? '599' : '59';

        qsos.add(QsoModel(
          callsign: qsoData['callsign'] ?? '',
          qsodate: qsoData['qsodate'] ?? '',
          qsotime: qsoData['qsotime'] ?? '',
          band: qsoData['band'] ?? '',
          mymode: qsoData['mymode'] ?? '',
          rstout: qsoData['rstout']?.isNotEmpty == true ? qsoData['rstout']! : defaultRst,
          rstin: qsoData['rstin']?.isNotEmpty == true ? qsoData['rstin']! : defaultRst,
          received: qsoData['received'] ?? '',
          xtra: qsoData['xtra'] ?? '',
          qsonr: qsoData['qsonr'] ?? '',
          gridsquare: qsoData['gridsquare'] ?? '',
          distance: qsoData['distance'] ?? '',
          myiota: qsoData['myiota'] ?? '',
          mysota: qsoData['mysota'] ?? '',
          mypota: qsoData['mypota'] ?? '',
          clublogEqslCall: myCallsign,
          activationId: activationId,
          contestId: contestId,
        ));
      }
    }

    return qsos;
  }
}
