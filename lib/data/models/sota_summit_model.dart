class SotaSummitModel {
  int? id;
  String summitCode; // e.g. G/LD-001
  String associationName;
  String regionName;
  String summitName;
  int altM;
  int altFt;
  String? gridRef1;
  String? gridRef2;
  double? longitude;
  double? latitude;
  int points;
  int bonusPoints;
  String? validFrom;
  String? validTo;
  int activationCount;
  String? activationDate;
  String? activationCall;

  SotaSummitModel({
    this.id,
    required this.summitCode,
    required this.associationName,
    required this.regionName,
    required this.summitName,
    required this.altM,
    required this.altFt,
    this.gridRef1,
    this.gridRef2,
    this.longitude,
    this.latitude,
    required this.points,
    this.bonusPoints = 0,
    this.validFrom,
    this.validTo,
    this.activationCount = 0,
    this.activationDate,
    this.activationCall,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'summit_code': summitCode,
      'association_name': associationName,
      'region_name': regionName,
      'summit_name': summitName,
      'alt_m': altM,
      'alt_ft': altFt,
      'grid_ref1': gridRef1,
      'grid_ref2': gridRef2,
      'longitude': longitude,
      'latitude': latitude,
      'points': points,
      'bonus_points': bonusPoints,
      'valid_from': validFrom,
      'valid_to': validTo,
      'activation_count': activationCount,
      'activation_date': activationDate,
      'activation_call': activationCall,
    };
  }

  factory SotaSummitModel.fromMap(Map<String, dynamic> map) {
    return SotaSummitModel(
      id: map['id'] as int?,
      summitCode: map['summit_code'] as String? ?? '',
      associationName: map['association_name'] as String? ?? '',
      regionName: map['region_name'] as String? ?? '',
      summitName: map['summit_name'] as String? ?? '',
      altM: map['alt_m'] as int? ?? 0,
      altFt: map['alt_ft'] as int? ?? 0,
      gridRef1: map['grid_ref1'] as String?,
      gridRef2: map['grid_ref2'] as String?,
      longitude: map['longitude'] as double?,
      latitude: map['latitude'] as double?,
      points: map['points'] as int? ?? 0,
      bonusPoints: map['bonus_points'] as int? ?? 0,
      validFrom: map['valid_from'] as String?,
      validTo: map['valid_to'] as String?,
      activationCount: map['activation_count'] as int? ?? 0,
      activationDate: map['activation_date'] as String?,
      activationCall: map['activation_call'] as String?,
    );
  }

  factory SotaSummitModel.fromCsv(List<String> fields) {
    return SotaSummitModel(
      summitCode: fields[0].trim(),
      associationName: fields[1].trim(),
      regionName: fields[2].trim(),
      summitName: fields[3].trim(),
      altM: int.tryParse(fields[4].trim()) ?? 0,
      altFt: int.tryParse(fields[5].trim()) ?? 0,
      gridRef1: fields[6].trim().isEmpty ? null : fields[6].trim(),
      gridRef2: fields[7].trim().isEmpty ? null : fields[7].trim(),
      longitude: double.tryParse(fields[8].trim()),
      latitude: double.tryParse(fields[9].trim()),
      points: int.tryParse(fields[10].trim()) ?? 0,
      bonusPoints: int.tryParse(fields[11].trim()) ?? 0,
      validFrom: fields[12].trim().isEmpty ? null : fields[12].trim(),
      validTo: fields[13].trim().isEmpty ? null : fields[13].trim(),
      activationCount: int.tryParse(fields[14].trim()) ?? 0,
      activationDate: fields.length > 15 && fields[15].trim().isNotEmpty ? fields[15].trim() : null,
      activationCall: fields.length > 16 && fields[16].trim().isNotEmpty ? fields[16].trim() : null,
    );
  }

  /// Check if summit is currently valid
  bool get isValid {
    if (validTo == null || validTo!.isEmpty) return true;
    try {
      final toDate = DateTime.parse(validTo!);
      return DateTime.now().isBefore(toDate);
    } catch (_) {
      return true;
    }
  }

  /// Display name combining code and name
  String get displayName => '$summitCode - $summitName';

  /// Full location string
  String get location => '$associationName / $regionName';
}
