import 'package:flutter/material.dart';

/// Obsidian Kinetic — the palette from
/// `stitch/stitch_deep_fitness_member_app/obsidian_kinetic/DESIGN.md`.
///
/// Dark only, by design: the gym is dimly lit and the screens are read at
/// arm's length under harsh overhead light. Depth comes from tonal
/// layering and 1px borders, never from shadows or glows, because a soft
/// shadow washes out under that lighting.
///
/// The accent is deliberately scarce — primary actions, the active tab,
/// and telemetry. It is never a large flat surface.
abstract final class AppColors {
  const AppColors._();

  // ------------------------------------------------------------- surfaces
  /// Level 0, the canvas everything sits on.
  static const surface = Color(0xFF121315);
  static const surfaceDim = Color(0xFF121315);
  static const surfaceBright = Color(0xFF38393B);

  /// Below the canvas: the app bar and the bottom nav.
  static const surfaceContainerLowest = Color(0xFF0D0E10);

  /// Level 1, cards.
  static const surfaceContainerLow = Color(0xFF1B1C1E);
  static const surfaceContainer = Color(0xFF1F2022);

  /// Level 2, sheets and raised chips.
  static const surfaceContainerHigh = Color(0xFF292A2C);
  static const surfaceContainerHighest = Color(0xFF343537);
  static const surfaceVariant = Color(0xFF343537);

  // ------------------------------------------------------------- contents
  static const onSurface = Color(0xFFE3E2E5);
  static const onSurfaceVariant = Color(0xFFCBC7AA);
  static const outline = Color(0xFF959277);
  static const outlineVariant = Color(0xFF494831);

  // -------------------------------------------------------------- accents
  /// The athletic yellow. Primary buttons, the active tab, progress.
  static const primaryContainer = Color(0xFFF1E800);

  /// Pressed state for the yellow.
  static const primaryContainerDim = Color(0xFFD3CB00);

  /// Text and icons sitting on the yellow.
  static const onPrimaryContainer = Color(0xFF1E1C00);

  /// White, used for headings and metric numerals.
  static const primary = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFF343200);

  static const secondary = Color(0xFFC2C6D1);
  static const secondaryContainer = Color(0xFF424750);
  static const onSecondaryContainer = Color(0xFFB1B5C0);

  /// Used for the "done" tick and positive telemetry.
  static const tertiaryContainer = Color(0xFF97F2F2);
  static const onTertiaryContainer = Color(0xFF007071);

  // ------------------------------------------------------------ semantics
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF12A86B);
}

/// Spacing, on the 8pt rhythm the design system sets out.
abstract final class Insets {
  const Insets._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// The outer canvas margin. Fixed at 16, so a tap near the edge does
  /// not land off the control.
  static const margin = 16.0;
}

/// Corner radii.
abstract final class Radii {
  const Radii._();

  static const sm = 4.0;

  /// Cards and inputs.
  static const base = 8.0;
  static const md = 12.0;

  /// Sheets and overview panels.
  static const lg = 16.0;
  static const xl = 24.0;

  /// Badges, chips and pills.
  static const full = 999.0;
}

/// The minimum tap target. Sweaty fingers, mid-set.
const double kMinTouchTarget = 48;
