import 'package:flutter/material.dart';

class ActivationModel {
  int? id;
  String type; // pota, iota, gma, sota, cota, lighthouse, custom
  String reference;
  String title;
  String description;
  String? imagePath;
  String contestId;
  bool showInDropdown;

  ActivationModel({
    this.id,
    this.type = '',
    this.reference = '',
    this.title = '',
    this.description = '',
    this.imagePath,
    this.contestId = '',
    this.showInDropdown = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'reference': reference,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'contest_id': contestId,
      'show_in_dropdown': showInDropdown ? 1 : 0,
    };
  }

  factory ActivationModel.fromMap(Map<String, dynamic> map) {
    return ActivationModel(
      id: map['id'] as int?,
      type: map['type']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imagePath: map['image_path']?.toString(),
      contestId: map['contest_id']?.toString() ?? '',
      showInDropdown: (map['show_in_dropdown'] as int?) != 0,
    );
  }

  ActivationModel copyWith({
    int? id,
    String? type,
    String? reference,
    String? title,
    String? description,
    String? imagePath,
    String? contestId,
    bool? showInDropdown,
  }) {
    return ActivationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      contestId: contestId ?? this.contestId,
      showInDropdown: showInDropdown ?? this.showInDropdown,
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
