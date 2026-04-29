import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E0E14),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C8EFF),
        secondary: Color(0xFF9B6CFF),
        surface: Color(0xFF1A1A26),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB0B0C8),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 14),
        bodyMedium: TextStyle(color: Color(0xFFB0B0C8), fontSize: 12),
        bodySmall: TextStyle(color: Color(0xFF808098), fontSize: 10),
        labelMedium: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: Color(0xFF808098), fontSize: 10),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252535),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C8EFF)),
        ),
        hintStyle: const TextStyle(color: Color(0xFF606080)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C8EFF),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6C8EFF),
        ),
      ),
    );
  }

  // Track color palette — index 0 is always Main
  static const List<Color> trackColors = [
    Color(0xFF4A90D9), // Main: blue
    Color(0xFFF5A623), // Clone: amber
    Color(0xFF7ED321), // Clone: green
    Color(0xFFBD10E0), // Clone: purple
    Color(0xFFFF6B6B), // Clone: coral
    Color(0xFF4ECDC4), // Clone: teal
    Color(0xFFFFD700), // Clone: gold
    Color(0xFFFF8C42), // Clone: orange
  ];

  static Color trackColorAt(int index) =>
      trackColors[index % trackColors.length];

  // Glass layer clip base color (semi-transparent)
  static Color clipFill(Color base) => base.withOpacity(0.22);
  static Color clipBorder(Color base) => base.withOpacity(0.55);
  static Color clipHighlight(Color base) => base.withOpacity(0.12);
}
