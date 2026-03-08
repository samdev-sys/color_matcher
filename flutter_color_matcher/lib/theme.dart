import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00A895);
  static const Color background = Color(0xFFF1F3F2);
  static const Color backgroundDark = Color(0xFF141218);
  static const Color backgroundCard = Color(0xFF1C1B21);
  static const Color textPrimary = Color(0xFF1C1B21);
  
  static const Color surface = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      fontFamily: 'Roboto', // Default, using Google Fonts in widgets
    );
  }
}
