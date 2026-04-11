import 'package:flutter/material.dart';

class AppTheme {
  static final lightColors = AppColors(
    primary: const Color(0xFF2F80ED), // Main blue
    bg: const Color(0xFFF5F9FF), // Background
    text: const Color(0xFF1F2937), // Dark text
    light: const Color(0xFF9CA3AF), // Secondary text
    card: Colors.white, // Card background
    border: const Color(0xFFE5EAF2), // Light border
    danger: const Color(0xFFEB5757), // Delete red
    success: const Color(0xFF27AE60), // Optional green
  );

  static final darkColors = AppColors(
    primary: const Color(0xFF4DA3FF),
    bg: const Color(0xFF121212),
    text: const Color(0xFFE5E7EB),
    light: const Color(0xFF9CA3AF),
    card: const Color(0xFF1E1E1E),
    border: const Color(0xFF2C2C2C),
    danger: const Color(0xFFEB5757),
    success: const Color(0xFF27AE60),
  );

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightColors.bg,
    primaryColor: lightColors.primary,

    colorScheme: ColorScheme.light(
      primary: lightColors.primary,
      surface: lightColors.bg,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: lightColors.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: lightColors.text),
      titleTextStyle: TextStyle(
        color: lightColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: lightColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lightColors.border),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),

    textTheme: TextTheme(
      bodyLarge: TextStyle(color: lightColors.text),
      bodyMedium: TextStyle(color: lightColors.text),
      labelMedium: TextStyle(color: lightColors.light),
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkColors.bg,
    primaryColor: darkColors.primary,

    colorScheme: ColorScheme.dark(
      primary: darkColors.primary,
      surface: darkColors.bg,
    ),

    cardTheme: CardThemeData(
      color: darkColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkColors.border),
      ),
    ),
  );
}

@immutable
class AppColors {
  final Color primary;
  final Color bg;
  final Color text;
  final Color light;
  final Color card;
  final Color border;
  final Color danger;
  final Color success;

  const AppColors({
    required this.primary,
    required this.bg,
    required this.text,
    required this.light,
    required this.card,
    required this.border,
    required this.danger,
    required this.success,
  });
}
