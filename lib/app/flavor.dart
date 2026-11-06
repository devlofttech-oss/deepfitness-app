import 'package:flutter/foundation.dart';

/// Which Firebase project this build talks to.
///
/// The guide keeps two: `deepfitness-dev` and `deepfitness-prod`. The flavor
/// is chosen at build time and nothing in the app can change it afterwards.
enum Flavor {
  dev('deepfitness-dev', 'Deep Fitness Dev'),
  prod('deepfitness-prod', 'Deep Fitness');

  const Flavor(this.projectId, this.appName);

  /// The Firebase project this flavor belongs to.
  final String projectId;

  /// What the launcher and the title bar say, so a dev build is obvious on a
  /// phone that has both installed.
  final String appName;

  bool get isProd => this == Flavor.prod;

  static const String _name = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Dev unless the build explicitly says otherwise, so forgetting the define
  /// is harmless rather than dangerous.
  static Flavor get current => values.firstWhere(
    (flavor) => flavor.name == _name,
    orElse: () => Flavor.dev,
  );

  /// Escape hatch for the rare debug session against production, which has to
  /// be asked for by name:
  ///
  ///   --dart-define=FLAVOR=prod --dart-define=ALLOW_PROD_DEBUG=true
  static const bool _allowProdDebug = bool.fromEnvironment(
    'ALLOW_PROD_DEBUG',
  );

  /// Fails the build's startup rather than letting a developer write test data
  /// into the live gym's records. The guide is explicit that a debug build
  /// never points at production.
  static void assertSafeForBuildMode() {
    if (!current.isProd) return;
    if (kReleaseMode || _allowProdDebug) return;

    throw StateError(
      'This is a debug build pointed at ${current.projectId}. Build with '
      '--dart-define=FLAVOR=dev, or pass '
      '--dart-define=ALLOW_PROD_DEBUG=true if you really mean it.',
    );
  }
}
