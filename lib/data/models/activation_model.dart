class ActivationModel {
  int? id;
  String type; // pota, iota, gma, sota, cota, custom
  String reference;

  ActivationModel({
    this.id,
    this.type = '',
    this.reference = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'reference': reference,
    };
  }

  factory ActivationModel.fromMap(Map<String, dynamic> map) {
    return ActivationModel(
      id: map['id'] as int?,
      type: map['type'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
    );
  }

  ActivationModel copyWith({
    int? id,
    String? type,
    String? reference,
  }) {
    return ActivationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      reference: reference ?? this.reference,
    );
  }

  static const List<String> activationTypes = [
    'pota',
    'iota',
    'gma',
    'sota',
    'cota',
    'custom',
  ];
}
