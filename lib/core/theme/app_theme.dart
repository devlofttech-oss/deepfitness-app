import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app ships in a single dark theme. There is no light variant on
/// purpose: every screen is designed against the near-black canvas, so a
/// light mode would only ever be a half-finished second skin.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build();

  static ThemeData _build() {
    const textColor = AppColors.white;
    const surfaceColor = AppColors.slate;
    const backgroundColor = AppColors.night;
    const borderColor = AppColors.borderDark;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.gold,
            primary: AppColors.gold,
            surface: surfaceColor,
            brightness: Brightness.dark,
          ).copyWith(
            // fromSeed derives warm brown-tinted containers from the orange
            // seed; pin them to the neutral greys the screens actually use so
            // dialogs, sheets, and menus match the cards.
            onPrimary: AppColors.black,
            onSurface: textColor,
            surfaceContainerLowest: AppColors.night,
            surfaceContainerLow: AppColors.slate,
            surfaceContainer: AppColors.slate,
            surfaceContainerHigh: AppColors.charcoal,
            surfaceContainerHighest: AppColors.charcoal,
            outline: borderColor,
            outlineVariant: borderColor,
          ),
    );

    // San Francisco is Apple's system font and can't be bundled into an
    // Android/web build, so on iOS/macOS we point at the real system font
    // via Flutter's special ".SF Pro" family names (resolved natively by
    // the OS, nothing to embed). Everywhere else we fall back to Inter, a
    // free, geometrically close match to SF Pro.
    final isApplePlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final interTheme = GoogleFonts.interTextTheme(base.textTheme);
    final baseTextTheme = isApplePlatform
        ? interTheme.apply(fontFamily: '.SF Pro Text')
        : interTheme;
    final displayTextTheme = isApplePlatform
        ? interTheme.apply(fontFamily: '.SF Pro Display')
        : interTheme;

    final textTheme = baseTextTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
    final displayApplied = displayTextTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme.copyWith(
        // Apple pairs its larger display/headline sizes with the "Display"
        // optical size of SF Pro; the rest of the type scale uses "Text".
        displayLarge: displayApplied.displayLarge?.copyWith(
          fontSize: 40,
          height: 1.08,
          color: textColor,
        ),
        displaySmall: displayApplied.displaySmall?.copyWith(
          fontSize: 30,
          height: 1.12,
          color: textColor,
        ),
        headlineMedium: displayApplied.headlineMedium?.copyWith(
          fontSize: 22,
          height: 1.18,
          color: textColor,
        ),
        headlineSmall: displayApplied.headlineSmall?.copyWith(
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
      dividerTheme: const DividerThemeData(color: borderColor),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        dragHandleColor: AppColors.mutedDark,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: AppColors.mutedDark),
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
