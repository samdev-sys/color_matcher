import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6A1B9A); // A deep, vibrant purple
  static const Color primaryDark = Color(0xFF4A148C); // A darker shade for gradients or hover states
  static const Color accent = Color(0xFFFFD600); // A bright, contrasting yellow

  static const Color background = Color(0xFFF5F5F5); // A light, clean grey for backgrounds
  static const Color backgroundCard = Color(0xFF2C2C2E); // Dark card background
  static const Color backgroundDark = Color(0xFF1C1C1E); // A very dark grey for main background

  static const Color textPrimary = Color(0xFF212121); // For headlines and important text
  static const Color textSecondary = Colors.black54; // For supporting text

  static const Color success = Color(0xFF2E7D32); // For success states
  static const Color error = Color(0xFFC62828); // For error states
  static const Color warning = Color(0xFFF9A825); // For warnings
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}
