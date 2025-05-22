import 'package:flutter/material.dart';

class Constants {
  static const Color kPrimary = Color(0xFF003366); // Dark Royal Blue

  static const MaterialColor kSwatchColor = MaterialColor(
    0xFF003366, // Base color
    <int, Color>{
      50: Color(0xFFE0E7F1),
      100: Color(0xFFB3C2DB),
      200: Color(0xFF809AC3),
      300: Color(0xFF4D72AB),
      400: Color(0xFF265496),
      500: Color(0xFF003366), // Dark Royal Blue
      600: Color(0xFF002E5E),
      700: Color(0xFF002651),
      800: Color(0xFF001F44),
      900: Color(0xFF001433),
    },
  );

  static int? juzIndex;
  static int? surahIndex;
}
