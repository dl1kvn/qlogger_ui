class ActivationImageModel {
  int? id;
  int activationId;
  String imagePath;
  int sortOrder;

  ActivationImageModel({
    this.id,
    required this.activationId,
    required this.imagePath,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'activation_id': activationId,
      'image_path': imagePath,
      'sort_order': sortOrder,
    };
  }

  factory ActivationImageModel.fromMap(Map<String, dynamic> map) {
    return ActivationImageModel(
      id: map['id'] as int?,
      activationId: map['activation_id'] as int,
      imagePath: map['image_path']?.toString() ?? '',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  ActivationImageModel copyWith({
    int? id,
    int? activationId,
    String? imagePath,
    int? sortOrder,
  }) {
    return ActivationImageModel(
      id: id ?? this.id,
      activationId: activationId ?? this.activationId,
      imagePath: imagePath ?? this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
