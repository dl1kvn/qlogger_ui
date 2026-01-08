import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const bg = Color(0xFFF7F7F9);

  // Button colors
  static const btnClear = Color(0xFFDA5656);
  static const btnClearFg = Colors.white;
  static const btnLog = Color(0xFF46DE7E);
  static const btnLogFg = Colors.white;

  // Status colors
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Text colors
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFFBB6E5F);

  // Surface colors
  static const surfaceLight = Color(0xFFE5E7EB);

  // AppBar colors
  static const appBarTitle = Color(0xFF5F501E);

  // Dropdown background colors (editable here)
  static const dropdownCallsign = Color(0xFFE3F1A4); // Light Blue
  static const dropdownActivation = Color(0xFFEFC279); // Light Orange
  static const dropdownSatellite = Color(0xFFB8F8F6); // Light Green
}

ColorScheme buildLightScheme() {
  return ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );
}
