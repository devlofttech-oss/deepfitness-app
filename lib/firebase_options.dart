// Generated-file placeholder.
//
// Run `flutterfire configure --project=deepfitness-dev` (and again for
// `deepfitness-prod`) to replace this file with the real generated options.
// Until then the values come from --dart-define so a build can be pointed at a
// project without committing any keys:
//
//   flutter run \
//     --dart-define=FIREBASE_API_KEY=... \
//     --dart-define=FIREBASE_APP_ID=... \
//     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
//     --dart-define=FIREBASE_PROJECT_ID=deepfitness-dev \
//     --dart-define=FIREBASE_STORAGE_BUCKET=deepfitness-dev.appspot.com
//
// On Android and iOS the native google-services.json / GoogleService-Info.plist
// take precedence once they are in place, so these defines are only needed for
// Web and for builds made before `flutterfire configure` has been run.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.devloft.deepfitness',
  );
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );

  /// True when enough has been supplied to initialise Firebase from Dart.
  ///
  /// Android and iOS can still initialise from their native config files, so
  /// those platforms are allowed through without the defines.
  static bool get isConfigured {
    if (projectId.isNotEmpty && appId.isNotEmpty && apiKey.isNotEmpty) {
      return true;
    }
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Null when the platform should initialise from its native config file.
  static FirebaseOptions? get currentPlatform {
    if (projectId.isEmpty || appId.isEmpty || apiKey.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      authDomain: authDomain.isEmpty ? null : authDomain,
      iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
          ? iosBundleId
          : null,
    );
  }
}
