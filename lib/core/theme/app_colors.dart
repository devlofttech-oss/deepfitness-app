import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const night = Color(0xFF252C33);
  static const slate = Color(0xFF3A4750);
  static const gold = Color(0xFFF6C90E);
  static const goldBright = Color(0xFFF6C90E);
  static const goldSoft = Color(0xFFFFF5D8);
  static const darkGoldSoft = Color(0xFF3E371C);
  static const black = Color(0xFF111111);
  static const charcoal = Color(0xFF222222);
  static const background = Color(0xFFEEEEEE);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6E6E73);
  static const mutedDark = Color(0xFFB8C0C7);
  static const border = Color(0xFFE8E8E8);
  static const borderDark = Color(0xFF46535C);
  static const success = Color(0xFF12A86B);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color text(BuildContext context) => isDark(context) ? white : black;

  static Color surface(BuildContext context) => isDark(context) ? slate : white;

  static Color canvas(BuildContext context) =>
      isDark(context) ? night : background;

  static Color subtle(BuildContext context) =>
      isDark(context) ? night : background;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? mutedDark : muted;

  static Color divider(BuildContext context) =>
      isDark(context) ? borderDark : border;

  static Color chipBackground(BuildContext context) =>
      isDark(context) ? darkGoldSoft : goldSoft;
}
