class IotaIslandModel {
  int? id;
  String groupRef; // e.g. EU-095
  String? subgroupRef; // e.g. EU-095S (nullable)
  String name;
  String? altNames;
  double? lat;
  double? lon;
  bool active;

  IotaIslandModel({
    this.id,
    required this.groupRef,
    this.subgroupRef,
    required this.name,
    this.altNames,
    this.lat,
    this.lon,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'group_ref': groupRef,
      'subgroup_ref': subgroupRef,
      'name': name,
      'alt_names': altNames,
      'lat': lat,
      'lon': lon,
      'active': active ? 1 : 0,
    };
  }

  factory IotaIslandModel.fromMap(Map<String, dynamic> map) {
    return IotaIslandModel(
      id: map['id'] as int?,
      groupRef: map['group_ref'] as String? ?? '',
      subgroupRef: map['subgroup_ref'] as String?,
      name: map['name'] as String? ?? '',
      altNames: map['alt_names'] as String?,
      lat: map['lat'] as double?,
      lon: map['lon'] as double?,
      active: (map['active'] as int?) == 1,
    );
  }

  IotaIslandModel copyWith({
    int? id,
    String? groupRef,
    String? subgroupRef,
    String? name,
    String? altNames,
    double? lat,
    double? lon,
    bool? active,
  }) {
    return IotaIslandModel(
      id: id ?? this.id,
      groupRef: groupRef ?? this.groupRef,
      subgroupRef: subgroupRef ?? this.subgroupRef,
      name: name ?? this.name,
      altNames: altNames ?? this.altNames,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      active: active ?? this.active,
    );
  }
}
