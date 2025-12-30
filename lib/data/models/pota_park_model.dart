class PotaParkModel {
  int? id;
  String reference; // e.g. US-0001
  String name;
  bool active;
  int? entityId;
  String? locationDesc; // e.g. US-ME
  double? latitude;
  double? longitude;
  String? grid; // e.g. FN54vh

  PotaParkModel({
    this.id,
    required this.reference,
    required this.name,
    this.active = true,
    this.entityId,
    this.locationDesc,
    this.latitude,
    this.longitude,
    this.grid,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'reference': reference,
      'name': name,
      'active': active ? 1 : 0,
      'entity_id': entityId,
      'location_desc': locationDesc,
      'latitude': latitude,
      'longitude': longitude,
      'grid': grid,
    };
  }

  factory PotaParkModel.fromMap(Map<String, dynamic> map) {
    return PotaParkModel(
      id: map['id'] as int?,
      reference: map['reference'] as String? ?? '',
      name: map['name'] as String? ?? '',
      active: (map['active'] as int?) == 1,
      entityId: map['entity_id'] as int?,
      locationDesc: map['location_desc'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      grid: map['grid'] as String?,
    );
  }

  PotaParkModel copyWith({
    int? id,
    String? reference,
    String? name,
    bool? active,
    int? entityId,
    String? locationDesc,
    double? latitude,
    double? longitude,
    String? grid,
  }) {
    return PotaParkModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      name: name ?? this.name,
      active: active ?? this.active,
      entityId: entityId ?? this.entityId,
      locationDesc: locationDesc ?? this.locationDesc,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      grid: grid ?? this.grid,
    );
  }
}
