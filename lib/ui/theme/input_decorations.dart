import 'package:flutter/material.dart';

class InputStyles {
  static const EdgeInsets contentPaddingBig = EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 7,
  );

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 6,
  );

  static const EdgeInsets contentPaddingTight = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 6,
  );

  static const TextStyle labelSmall = TextStyle(fontSize: 11);

  static InputDecoration field(String label) => InputDecoration(
    labelText: label,
    labelStyle: labelSmall,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: contentPadding,
  );

  static InputDecoration fieldSmall(String label) => InputDecoration(
    labelText: label,
    labelStyle: labelSmall,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: contentPadding,
  );

  static InputDecoration fieldTight(String label) => InputDecoration(
    labelText: label,
    labelStyle: labelSmall,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: contentPaddingTight,
  );

  static InputDecoration fieldFilled(String label) => InputDecoration(
    labelText: label,
    labelStyle: labelSmall,
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: const OutlineInputBorder(),
    contentPadding: contentPaddingBig,
  );

  // Dropdown styles
  static const EdgeInsets dropdownPadding = EdgeInsets.symmetric(
    horizontal: 1,
    vertical: 1,
  );

  static InputDecoration dropdown(String label) => InputDecoration(
    labelText: label,
    labelStyle: labelSmall,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: dropdownPadding,
  );
}
