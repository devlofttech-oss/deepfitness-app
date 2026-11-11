import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Whether this build should talk to the local emulator suite.
///
/// Set with `flutter run --dart-define=USE_EMULATOR=true`, as the
/// developer guide's setup step describes. It is a compile-time constant,
/// so a release build cannot be pointed at a developer's laptop by a
/// stray environment variable.
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// An override for the emulator host, for a physical device on the same
/// network as the machine running the suite.
const String _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// The host the emulators are reachable on.
///
/// An Android emulator reaches its host machine through 10.0.2.2, not
/// loopback, which points at the emulated device itself.
String get emulatorHost {
  if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
  return defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
}

/// Points every SDK at the local suite. Ports match `firebase.json`.
Future<void> connectToEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
  await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
}

/// Turns analytics and crash reporting on, and only in release builds.
///
/// The developer guide is explicit that both are off in debug: a
/// developer stepping through a screen should not land in the gym's
/// funnels, and a deliberate crash while testing should not page anyone.
Future<void> configureTelemetry() async {
  final enabled = kReleaseMode && !useEmulator;

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);

  if (!enabled) return;

  // Flutter framework errors, and anything the framework did not catch.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Analytics, for the screens that record a navigation.
FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
