import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/presentation/onboarding_screen.dart';
import 'package:deepfitness/features/auth/presentation/sign_in_screen.dart';
import 'package:deepfitness/features/auth/presentation/verify_code_screen.dart';
import 'package:deepfitness/features/home/presentation/home_screen.dart';
import 'package:deepfitness/features/splash/presentation/splash_screen.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    // The single redirect guard the document asks for: signed out to sign
    // in, signed in without a profile to onboarding, otherwise home.
    redirect: (context, state) {
      final path = state.uri.path;

      if (session.isLoading && !session.hasValue) {
        return path == '/splash' ? null : '/splash';
      }

      final stage = session.value?.stage ?? AuthStage.signedOut;
      final isSignInRoute = path == '/sign-in' || path == '/verify';

      return switch (stage) {
        AuthStage.signedOut => isSignInRoute ? null : '/sign-in',
        AuthStage.needsProfile => path == '/onboarding' ? null : '/onboarding',
        AuthStage.ready => isSignInRoute ||
                path == '/onboarding' ||
                path == '/splash'
            ? '/'
            : null,
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) =>
            VerifyCodeScreen(pending: state.extra! as PendingVerification),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
  );
});
