import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.teal;
  static const secondary = Colors.orangeAccent;

  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;

  static const textDark = Colors.black87;
  static const textLight = Colors.white;
  static const textGrey = Colors.grey;

  static const error = Colors.redAccent;
  static const success = Colors.green;
  static const warning = Colors.amber;
}

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const body = TextStyle(
    fontSize: 15,
    color: AppColors.textDark,
  );
  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.5,
  );
}

class AppButtonStyles {
  static final elevated = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  static final outlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 2),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textDark,
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.elevated),
    outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.outlined),
  );
}

