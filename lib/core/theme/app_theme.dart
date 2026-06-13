import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),
    );
    final textTheme = GoogleFonts.poppinsTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.black, displayColor: AppColors.black);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontSize: 40,
          height: 1.08,
          color: AppColors.black,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontSize: 30,
          height: 1.12,
          color: AppColors.black,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 22,
          height: 1.18,
          color: AppColors.black,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 19,
          height: 1.2,
          color: AppColors.black,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 17,
          height: 1.25,
          color: AppColors.black,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 14,
          height: 1.3,
          color: AppColors.black,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontSize: 13,
          height: 1.3,
          color: AppColors.black,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 13,
          height: 1.35,
          color: AppColors.black,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          height: 1.35,
          color: AppColors.black,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.25,
          color: AppColors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.black,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
    );
  }
}
