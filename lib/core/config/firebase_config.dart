import 'package:deepfitness/firebase_options.dart';

/// Build-time Firebase settings that are not part of [DefaultFirebaseOptions].
class FirebaseConfig {
  const FirebaseConfig._();

  /// `firebase emulators:start` + `--dart-define=USE_EMULATOR=true` points the
  /// SDKs at localhost instead of the real project.
  static const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

  /// Host the emulator suite binds to. The Android emulator reaches the host
  /// machine on 10.0.2.2 rather than localhost.
  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  static const int storageEmulatorPort = 9199;
  static const int functionsEmulatorPort = 5001;

  /// Default country code applied to a phone number typed without one.
  static const String defaultPhoneCountryCode = '+91';

  static bool get isConfigured => DefaultFirebaseOptions.isConfigured;
}
