import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/config/firebase_config.dart';
import 'package:deepfitness/app/flavor.dart';
import 'package:deepfitness/app/router.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Must be a top-level function: the isolate that runs it has none of the
/// app's state.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is dark-only, so the system bars are pinned to light icons over
  // the dark canvas instead of following the OS appearance setting.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.night,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await _initializeFirebase();

  runApp(const ProviderScope(child: DeepFitnessApp()));
}

Future<void> _initializeFirebase() async {
  // Before anything connects: a debug build must not reach production data.
  Flavor.assertSafeForBuildMode();

  if (!DefaultFirebaseOptions.isConfigured) {
    AppFirebase.markUnavailable();
    debugPrint(
      'Firebase is not configured for this build. Run flutterfire configure, '
      'or pass the FIREBASE_* dart-defines.',
    );
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (FirebaseConfig.useEmulator) {
      await _useEmulators();
    }

    // Analytics and Crashlytics stay off in debug, per the security checklist.
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
      kReleaseMode,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );

    if (kReleaseMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    AppFirebase.markInitialized();
  } catch (error, stackTrace) {
    AppFirebase.markUnavailable();
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'deepfitness',
        context: ErrorDescription('while initializing Firebase'),
      ),
    );
  }
}

Future<void> _useEmulators() async {
  final host = FirebaseConfig.emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(
    host,
    FirebaseConfig.authEmulatorPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    FirebaseConfig.firestoreEmulatorPort,
  );
  await FirebaseStorage.instance.useStorageEmulator(
    host,
    FirebaseConfig.storageEmulatorPort,
  );
}

class DeepFitnessApp extends ConsumerWidget {
  const DeepFitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Dark-only app: both slots get the same theme so the OS light/dark
    // setting can never flip a screen to a light palette.
    return MaterialApp.router(
      title: Flavor.current.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
