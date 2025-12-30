class IotaGroupModel {
  int? id;
  String ref; // e.g. EU-095
  String name;
  String continent; // e.g. EU
  String? dxcc;

  IotaGroupModel({
    this.id,
    required this.ref,
    required this.name,
    required this.continent,
    this.dxcc,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ref': ref,
      'name': name,
      'continent': continent,
      'dxcc': dxcc,
    };
  }

  factory IotaGroupModel.fromMap(Map<String, dynamic> map) {
    return IotaGroupModel(
      id: map['id'] as int?,
      ref: map['ref'] as String? ?? '',
      name: map['name'] as String? ?? '',
      continent: map['continent'] as String? ?? '',
      dxcc: map['dxcc'] as String?,
    );
  }

  IotaGroupModel copyWith({
    int? id,
    String? ref,
    String? name,
    String? continent,
    String? dxcc,
  }) {
    return IotaGroupModel(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      name: name ?? this.name,
      continent: continent ?? this.continent,
      dxcc: dxcc ?? this.dxcc,
    );
  }
}
