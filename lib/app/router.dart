import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/presentation/onboarding_screen.dart';
import 'package:deepfitness/features/auth/presentation/renewal_screen.dart';
import 'package:deepfitness/features/auth/presentation/sign_in_screen.dart';
import 'package:deepfitness/features/auth/presentation/verify_code_screen.dart';
import 'package:deepfitness/features/events/presentation/events_screen.dart';
import 'package:deepfitness/features/home/presentation/home_screen.dart';
import 'package:deepfitness/features/profile/presentation/profile_screen.dart';
import 'package:deepfitness/features/splash/presentation/splash_screen.dart';
import 'package:deepfitness/features/workout_plan/presentation/exercise_screen.dart';
import 'package:deepfitness/features/workout_plan/presentation/plan_screen.dart';
import 'package:deepfitness/features/workout_report/presentation/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes a lapsed member may still reach.
///
/// A lapse is a state, not a sign-out: the profile and the renewal screen
/// stay open, and training does not.
// Reports are included: a lapsed member keeps read access to their own
// history, which is the point of a lapse not being a sign-out.
const _lapsedAllowed = {'/renew', '/profile', '/reports'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;

      if (session.isLoading && !session.hasValue) {
        return path == '/splash' ? null : '/splash';
      }

      final value = session.value;
      final stage = value?.stage ?? AuthStage.signedOut;
      final isSignInRoute = path == '/sign-in' || path == '/verify';

      switch (stage) {
        case AuthStage.signedOut:
          return isSignInRoute ? null : '/sign-in';
        case AuthStage.needsProfile:
          return path == '/onboarding' ? null : '/onboarding';
        case AuthStage.ready:
          if (value?.isLapsed ?? false) {
            return _lapsedAllowed.contains(path) ? null : '/renew';
          }
          if (isSignInRoute || path == '/onboarding' || path == '/splash' ||
              path == '/renew') {
            return '/';
          }
          return null;
      }
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
      GoRoute(
        path: '/renew',
        builder: (context, state) => const RenewalScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/plan',
        builder: (context, state) => const PlanScreen(),
        routes: [
          GoRoute(
            path: 'exercise',
            builder: (context, state) => const ExerciseScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
