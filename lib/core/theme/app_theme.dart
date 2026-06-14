import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return _build(brightness: Brightness.light);
  }

  static ThemeData get dark {
    return _build(brightness: Brightness.dark);
  }

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final surfaceColor = isDark ? AppColors.slate : AppColors.white;
    final backgroundColor = isDark ? AppColors.night : AppColors.background;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        surface: surfaceColor,
        brightness: brightness,
      ),
    );
    final textTheme = GoogleFonts.poppinsTextTheme(
      base.textTheme,
    ).apply(bodyColor: textColor, displayColor: textColor);

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontSize: 40,
          height: 1.08,
          color: textColor,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          fontSize: 30,
          height: 1.12,
          color: textColor,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 22,
          height: 1.18,
          color: textColor,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 19,
          height: 1.2,
          color: textColor,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 17,
          height: 1.25,
          color: textColor,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 14,
          height: 1.3,
          color: textColor,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontSize: 13,
          height: 1.3,
          color: textColor,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 13,
          height: 1.35,
          color: textColor,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          height: 1.35,
          color: textColor,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.25,
          color: textColor,
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
    );
  }
}
