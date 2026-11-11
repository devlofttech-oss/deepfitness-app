import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/app/router.dart';
import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/core/constants/app_constants.dart';
import 'package:deepfitness/features/notifications/application/notification_handler.dart';
import 'package:deepfitness/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles a push that arrives while the app is not running.
///
/// It must be a top-level function: the background isolate has none of
/// the app's state and looks this up by name.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Nothing more to do here: the system tray shows the notification, and
  // the tap is handled by onMessageOpenedApp once the app is awake.
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
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase is the backend, so a failure here is fatal rather than
  // something to carry on past: there is nothing for the app to read.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  runApp(const ProviderScope(child: DeepFitnessApp()));
}

class DeepFitnessApp extends ConsumerStatefulWidget {
  const DeepFitnessApp({super.key});

  @override
  ConsumerState<DeepFitnessApp> createState() => _DeepFitnessAppState();
}

class _DeepFitnessAppState extends ConsumerState<DeepFitnessApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // After the first frame, so the router and the messenger both exist
    // before a notification tries to navigate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationHandlerProvider)
          .start(
            router: ref.read(appRouterProvider),
            messengerKey: _messengerKey,
          );
    });
  }

  @override
  void dispose() {
    ref.read(notificationHandlerProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Dark-only app: both slots get the same theme so the OS light/dark
    // setting cannot flip it.
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
