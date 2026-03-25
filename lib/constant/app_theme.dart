import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — matches existing app palette for visual consistency during migration
  static const primary = Color(0xFFF2647C);
  static const primaryDark = Color(0xFFCA445D);
  static const primaryLight = Color(0xFFF48FB1);

  // Backgrounds
  static const scaffold = Color(0xFFF4F4F4);
  static const surface = Colors.white;
  static const card = Colors.white;
  static const surfaceVariant = Color(0xFFF5F5F5);

  // Accent
  static const accent = Color(0xFFF59E0B);

  // Text
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF718096);
  static const textHint = Color(0xFFA0AEC0);

  // Borders
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);

  // Feedback
  static const success = Color(0xFF38A169);
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFDD6B20);
  static const info = Color(0xFF3182CE);

  // Legacy aliases (used in existing constant.dart)
  static const grey = Colors.grey;
  static const white = Colors.white;
  static const black = Colors.black;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        primarySwatch: Colors.red,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffold,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
}
