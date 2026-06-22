import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // BiteBalance Theme - Matching Figma

  // Background gradient colors (cream to warm gold/yellow)
  static const Color gradientTop = Color(0xFFFFFFE3); // Light cream
  static const Color gradientMiddle = Color(0xFFF5E6C8); // Warm yellow
  static const Color gradientBottom = Color(0xFFE8C97A); // Golden yellow

  // Primary brand colors
  static const Color terracotta = Color(
    0xFFB85440,
  ); // Terracotta red (login card)
  static const Color sageGreen = Color(0xFF7A9367); // Sage green (buttons)
  static const Color darkSage = Color(0xFF5C7A52); // Darker sage

  // Text colors
  static const Color brandBrown = Color(0xFFB85440); // BiteBalance text color
  static const Color textDark = Color(0xFF3A2E25);
  static const Color textMedium = Color(0xFF6B5B4E);
  static const Color textLight = Color(0xFF9C8B7D);
  static const Color white = Color(0xFFFFFFFF);

  // Card / surface
  static const Color cardBackground = Color(0xFFB85440);
  static const Color inputBackground = Color(0xFFFFFFFF);

  static const Color accentYellow = Color(0xFFD4A843);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.gradientTop,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        secondary: AppColors.sageGreen,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textDark,
      ),
      textTheme: GoogleFonts.montserratTextTheme(),
    );
  }
}
