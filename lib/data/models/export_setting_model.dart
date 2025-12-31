import 'dart:convert';

class ExportSettingModel {
  int? id;
  String name;
  String format; // 'adif' or 'cabrillo'
  String dateFormat; // 'YYYY-MM-DD' or 'YYYYMMDD'
  String bandFormat; // 'band' (20M) or 'freq' (14000)
  String fields; // JSON array of selected field names in order

  static const List<String> allFields = [
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
    'clublogEqslCall',
    'clublogstatus',
    'activationId',
  ];

  static const List<String> formats = ['adif', 'cabrillo'];
  static const List<String> dateFormats = ['YYYY-MM-DD', 'YYYYMMDD'];
  static const List<String> bandFormats = ['band', 'freq'];

  ExportSettingModel({
    this.id,
    this.name = '',
    this.format = 'adif',
    this.dateFormat = 'YYYYMMDD',
    this.bandFormat = 'band',
    this.fields = '[]',
  });

  List<String> get fieldsList {
    if (fields.isEmpty || fields == '[]') return [];
    try {
      return List<String>.from(jsonDecode(fields));
    } catch (_) {
      return [];
    }
  }

  set fieldsList(List<String> list) {
    fields = jsonEncode(list);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'format': format,
      'date_format': dateFormat,
      'band_format': bandFormat,
      'fields': fields,
    };
  }

  factory ExportSettingModel.fromMap(Map<String, dynamic> map) {
    return ExportSettingModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      format: map['format'] as String? ?? 'adif',
      dateFormat: map['date_format'] as String? ?? 'YYYYMMDD',
      bandFormat: map['band_format'] as String? ?? 'band',
      fields: map['fields'] as String? ?? '[]',
    );
  }

  ExportSettingModel copyWith({
    int? id,
    String? name,
    String? format,
    String? dateFormat,
    String? bandFormat,
    String? fields,
  }) {
    return ExportSettingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      dateFormat: dateFormat ?? this.dateFormat,
      bandFormat: bandFormat ?? this.bandFormat,
      fields: fields ?? this.fields,
    );
  }
}
