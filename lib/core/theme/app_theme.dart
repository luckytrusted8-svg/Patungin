// Hallmark · redesign: patungin · genre: modern-minimal/fintech · pre-emit critique: P5 H5 E5 S5 R5 V5
import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Clean & Bright Emerald Fintech Palette
  static const primary = Color(0xFF0D9488); // Teal 600 - clean fresh emerald
  static const primaryDark = Color(0xFF0F766E); // Teal 700
  static const primaryLight = Color(0xFF14B8A6); // Teal 500
  static const dark = Color(0xFF0F172A); // Slate 900 - crisp charcoal for high contrast text
  static const accent = Color(0xFFF59E0B); // Amber 500 - warm talangan gold
  static const mint = Color(0xFF14B8A6); // Teal 500
  static const mintSoft = Color(0xFFF0FDFA); // Teal 50 - clean soft wash
  static const mintBadge = Color(0xFFCCFBF1); // Teal 100

  // Neutral Colors (Clean Bright Light)
  static const backgroundLight = Color(0xFFF8FAFC); // Slate 50 - crisp off-white canvas
  static const surfaceLight = Color(0xFFFFFFFF); // Pure white cards & dialogs
  static const textPrimaryLight = Color(0xFF0F172A); // Slate 900 - clear & sharp
  static const textSecondaryLight = Color(0xFF64748B); // Slate 500 - gentle readable grey
  static const borderLight = Color(0xFFE2E8F0); // Slate 200 - clean crisp borders

  // Neutral Colors (Dark Fallback to Clean Bright)
  static const backgroundDark = Color(0xFFF8FAFC);
  static const surfaceDark = Color(0xFFFFFFFF);
  static const textPrimaryDark = Color(0xFF0F172A);
  static const textSecondaryDark = Color(0xFF64748B);
  static const borderDark = Color(0xFFE2E8F0);

  // Functional Colors
  static const error = Color(0xFFE11D48); // Rose 600
  static const success = Color(0xFF059669); // Emerald 600
  static const warning = Color(0xFFD97706); // Amber 600
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.dark,
      tertiary: AppColors.accent,
      surface: AppColors.surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1.5,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
        hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight.withValues(alpha: 0.6)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  // Consistent clean bright theme even if OS requests dark mode
  static ThemeData get darkTheme => lightTheme;
}
