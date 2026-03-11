import 'package:flutter/material.dart';

class AppTheme {
  // Core palette
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0D1626);
  static const Color surfaceElevated = Color(0xFF111E35);
  static const Color cardBg = Color(0xFF0F1A2E);
  static const Color accent = Color(0xFF1A6DFF);
  static const Color accentGlow = Color(0xFF3D8EFF);
  static const Color accentDim = Color(0xFF0D3A8A);
  static const Color textPrimary = Color(0xFFE8F0FF);
  static const Color textSecondary = Color(0xFF7A9CC8);
  static const Color textMuted = Color(0xFF3A567A);
  static const Color border = Color(0xFF162040);
  static const Color borderGlow = Color(0xFF1A4080);

  // Alert colors — each visually distinct
  static const Color alertHorn        = Color(0xFFFF6B00); // Orange
  static const Color alertSiren       = Color(0xFF1A6DFF); // Blue
  static const Color alertSafetyAlarm = Color(0xFFFF2244); // Red
  static const Color alertHeavy       = Color(0xFF00CC66); // Green
  static const Color alertBackground  = Color(0xFF00CC66); // Green (unused)

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: accent,
        secondary: accentGlow,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w900, letterSpacing: -1.5),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -1.0),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
      useMaterial3: true,
    );
  }
}