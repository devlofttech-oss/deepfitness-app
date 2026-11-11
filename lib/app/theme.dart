import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The type scale from the design system.
///
/// Two faces doing two jobs: Barlow Condensed for headings, metrics and
/// labels, where condensed letterforms buy screen width for big numbers;
/// Inter for anything that is read as a sentence.
abstract final class AppText {
  const AppText._();

  static TextStyle _condensed({
    required double size,
    required double height,
    required FontWeight weight,
    double tracking = 0,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color,
    );
  }

  static TextStyle _inter({
    required double size,
    required double height,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
    );
  }

  // Condensed headings and metrics.
  static TextStyle get displayLarge =>
      _condensed(size: 48, height: 52, weight: FontWeight.w700);
  static TextStyle get displayMobile =>
      _condensed(size: 36, height: 40, weight: FontWeight.w700);
  static TextStyle get headlineLarge =>
      _condensed(size: 32, height: 36, weight: FontWeight.w700);
  static TextStyle get headlineMedium =>
      _condensed(size: 24, height: 28, weight: FontWeight.w600);
  static TextStyle get headlineSmall =>
      _condensed(size: 20, height: 24, weight: FontWeight.w600);

  // Condensed labels. Uppercase, with positive tracking so they stay
  // legible in motion — the design system asks for +0.04 to +0.06em.
  static TextStyle get labelLarge => _condensed(
    size: 16,
    height: 20,
    weight: FontWeight.w600,
    tracking: 16 * 0.05,
  );
  static TextStyle get labelMedium => _condensed(
    size: 14,
    height: 16,
    weight: FontWeight.w600,
    tracking: 14 * 0.05,
  );
  static TextStyle get labelSmall => _condensed(
    size: 12,
    height: 14,
    weight: FontWeight.w600,
    tracking: 12 * 0.06,
  );

  // Inter body copy.
  static TextStyle get bodyLarge => _inter(size: 16, height: 24);
  static TextStyle get bodyMedium => _inter(size: 14, height: 20);
  static TextStyle get bodySmall => _inter(size: 12, height: 16);
}

abstract final class AppTheme {
  const AppTheme._();

  /// The only theme. There is no light palette and no toggle.
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      primary: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimaryContainer,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      // The system rejects ambient shadows: depth is tonal layering and
      // 1px borders, because a blur washes out under gym lighting.
      shadowColor: Colors.transparent,
    );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: AppText.displayLarge,
        displayMedium: AppText.displayMobile,
        displaySmall: AppText.headlineLarge,
        headlineLarge: AppText.headlineLarge,
        headlineMedium: AppText.headlineMedium,
        headlineSmall: AppText.headlineSmall,
        titleLarge: AppText.headlineSmall,
        titleMedium: AppText.labelLarge,
        titleSmall: AppText.labelMedium,
        labelLarge: AppText.labelLarge,
        labelMedium: AppText.labelMedium,
        labelSmall: AppText.labelSmall,
        bodyLarge: AppText.bodyLarge,
        bodyMedium: AppText.bodyMedium,
        bodySmall: AppText.bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.headlineSmall.copyWith(
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.base),
          side: const BorderSide(color: AppColors.surfaceContainerHigh),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          disabledBackgroundColor: AppColors.surfaceContainerHigh,
          disabledForegroundColor: AppColors.outline,
          // 52 is the floor the design system sets for a primary action.
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.base),
          ),
          textStyle: AppText.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          backgroundColor: AppColors.surfaceContainerLow,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.surfaceContainerHigh),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.base),
          ),
          textStyle: AppText.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.onSurfaceVariant,
          textStyle: AppText.labelMedium,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        constraints: const BoxConstraints(minHeight: 52),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.md,
        ),
        hintStyle: AppText.bodyMedium.copyWith(color: AppColors.outline),
        labelStyle: AppText.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        border: _inputBorder(AppColors.surfaceContainerHigh),
        enabledBorder: _inputBorder(AppColors.surfaceContainerHigh),
        // Focus is a 1px accent stroke, with no glow behind it.
        focusedBorder: _inputBorder(AppColors.primaryContainer),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primaryContainer,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: AppText.labelSmall,
        unselectedLabelStyle: AppText.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: AppText.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.base),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryContainer,
        linearTrackColor: AppColors.surfaceContainerHigh,
        circularTrackColor: AppColors.surfaceContainerHigh,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        side: const BorderSide(color: AppColors.surfaceContainerHigh),
        labelStyle: AppText.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.full),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color colour) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.base),
    borderSide: BorderSide(color: colour),
  );
}
