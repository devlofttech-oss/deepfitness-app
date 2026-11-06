import 'package:flutter/material.dart';

/// Central design-system palette.
///
/// The app is dark-only: a near-black canvas, slightly-lighter dark cards,
/// and a warm orange accent. The context-taking helpers below are kept so the
/// screens keep reading their colours from one place, but they all resolve to
/// the dark values now.
class AppColors {
  const AppColors._();

  static const night = Color(0xFF121212);
  static const slate = Color(0xFF1E1E1E);
  static const gold = Color(0xFFFF8A00);
  static const goldBright = Color(0xFFFF8A00);
  static const darkGoldSoft = Color(0xFF43290F);
  static const black = Color(0xFF1A1A1A);
  static const charcoal = Color(0xFF222222);
  static const graphite = Color(0xFF3A3A3A);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF9CA3AF);
  static const mutedDark = Color(0xFF9CA3AF);
  static const borderDark = Color(0xFF2A2A2A);
  static const success = Color(0xFF12A86B);
  static const danger = Color(0xFFFF6B6B);

  /// Always true; retained so existing `isDark(context)` call sites keep
  /// compiling while the app is locked to the dark theme.
  static bool isDark(BuildContext context) => true;

  static Color text(BuildContext context) => white;

  static Color surface(BuildContext context) => slate;

  static Color canvas(BuildContext context) => night;

  static Color subtle(BuildContext context) => night;

  static Color secondaryText(BuildContext context) => mutedDark;

  static Color divider(BuildContext context) => borderDark;

  static Color chipBackground(BuildContext context) => darkGoldSoft;
}
