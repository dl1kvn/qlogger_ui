import 'package:flutter/material.dart';
import 'color_scheme.dart';

class AppText {
  static TextTheme theme() => const TextTheme(
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(fontSize: 14, height: 1.3),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}

class FormStyles {
  static TextStyle callsign(double width) => TextStyle(
    fontSize: width * 0.05,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );

  static TextStyle rstIn(double width) => TextStyle(
    fontSize: width * 0.05,
    fontWeight: FontWeight.w500,
  );

  static TextStyle rstOut(double width) => TextStyle(
    fontSize: width * 0.05,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle info = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle dateTime = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

class ButtonStyles {
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class AppBarStyles {
  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.appBarTitle,
  );
}
