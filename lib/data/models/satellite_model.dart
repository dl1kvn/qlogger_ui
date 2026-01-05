class SatelliteModel {
  int? id;
  String name;
  String description;
  bool isActive;
  int sortOrder;

  SatelliteModel({
    this.id,
    this.name = '',
    this.description = '',
    this.isActive = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory SatelliteModel.fromMap(Map<String, dynamic> map) {
    return SatelliteModel(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isActive: (map['is_active'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  SatelliteModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    int? sortOrder,
  }) {
    return SatelliteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
