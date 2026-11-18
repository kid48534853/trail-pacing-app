import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgBase = Color(0xFF121316);
  static const Color bgSidebar = Color(0xFF181A1F);
  static const Color bgSurface = Color(0xFF1E2128);
  static const Color bgElevated = Color(0xFF262A33);
  static const Color borderColor = Color(0xFF2F3542);
  static const Color textMain = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color accentGreen = Color(0xFF84CC16);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFF43F5E);

  static ThemeData darkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgBase,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        onPrimary: Color(0xFF0F172A),
        secondary: accentBlue,
        surface: bgSurface,
        onSurface: textMain,
        error: accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSidebar,
        foregroundColor: textMain,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgBase,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentGreen, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: const Color(0xFF0F172A),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        selectedColor: accentGreen.withOpacity(0.2),
        side: const BorderSide(color: borderColor),
        labelStyle: const TextStyle(color: textMain, fontSize: 12),
      ),
    );
  }
}
