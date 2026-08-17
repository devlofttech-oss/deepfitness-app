import 'package:deepfitness/core/router/app_router.dart';
import 'package:deepfitness/core/constants/app_constants.dart';
import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/core/theme/app_theme.dart';
import 'package:deepfitness/services/supabase_service.dart';
import 'package:deepfitness/services/timeout_http_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';

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

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        httpClient: TimeoutHttpClient(),
      );
      SupabaseService.markInitialized();
    } catch (error, stackTrace) {
      SupabaseService.markUnavailable();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'deepfitness',
          context: ErrorDescription('while initializing Supabase'),
        ),
      );
    }
  }

  runApp(const ProviderScope(child: DeepFitnessApp()));
}

class DeepFitnessApp extends ConsumerWidget {
  const DeepFitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Dark-only app: both slots get the same theme so the OS light/dark
    // setting can never flip a screen to a light palette.
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
