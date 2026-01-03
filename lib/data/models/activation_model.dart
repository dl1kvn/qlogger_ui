import 'package:flutter/material.dart';

class ActivationModel {
  int? id;
  String type; // pota, iota, gma, sota, cota, lighthouse, custom
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
    'lighthouse',
    'custom',
  ];

  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'iota':
        return Icons.beach_access;
      case 'pota':
        return Icons.park;
      case 'cota':
        return Icons.castle;
      case 'lighthouse':
        return Icons.cell_tower;
      case 'sota':
        return Icons.terrain;
      case 'gma':
        return Icons.terrain;
      default:
        return Icons.radio;
    }
  }

  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'iota':
        return Colors.red;
      case 'pota':
        return const Color(0xFF43A047);
      case 'cota':
        return Colors.deepOrange;
      case 'lighthouse':
        return Colors.blue;
      case 'sota':
        return Colors.green;
      case 'gma':
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }
}
