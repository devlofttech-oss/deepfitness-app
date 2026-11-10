import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/app/router.dart';
import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/core/constants/app_constants.dart';
import 'package:deepfitness/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Firebase is the backend, so a failure here is fatal rather than
  // something to carry on past: there is nothing for the app to read.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: DeepFitnessApp()));
}

class DeepFitnessApp extends ConsumerWidget {
  const DeepFitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Dark-only app: both slots get the same theme so the OS light/dark
    // setting cannot flip it.
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
