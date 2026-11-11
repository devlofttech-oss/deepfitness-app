import 'package:deepfitness/admin/presentation/admin_announcements_screen.dart';
import 'package:deepfitness/admin/presentation/admin_classes_screen.dart';
import 'package:deepfitness/admin/presentation/admin_events_screen.dart';
import 'package:deepfitness/admin/presentation/admin_exercises_screen.dart';
import 'package:deepfitness/admin/presentation/admin_members_screen.dart';
import 'package:deepfitness/admin/presentation/admin_plans_screen.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/presentation/onboarding_screen.dart';
import 'package:deepfitness/features/auth/presentation/renewal_screen.dart';
import 'package:deepfitness/features/auth/presentation/sign_in_screen.dart';
import 'package:deepfitness/features/auth/presentation/verify_code_screen.dart';
import 'package:deepfitness/features/events/presentation/event_detail_screen.dart';
import 'package:deepfitness/features/events/presentation/events_screen.dart';
import 'package:deepfitness/features/group_classes/presentation/class_detail_screen.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_screen.dart';
import 'package:deepfitness/features/notifications/presentation/announcements_screen.dart';
import 'package:deepfitness/features/home/presentation/home_screen.dart';
import 'package:deepfitness/features/profile/presentation/edit_profile_screen.dart';
import 'package:deepfitness/features/profile/presentation/profile_screen.dart';
import 'package:deepfitness/features/shell/presentation/member_shell.dart';
import 'package:deepfitness/features/splash/presentation/splash_screen.dart';
import 'package:deepfitness/features/workout_plan/presentation/exercise_screen.dart';
import 'package:deepfitness/features/workout_plan/presentation/plan_history_screen.dart';
import 'package:deepfitness/features/workout_plan/presentation/plan_screen.dart';
import 'package:deepfitness/features/workout_report/presentation/report_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes a lapsed member may still reach.
///
/// A lapse is a state, not a sign-out: the profile and the renewal screen
/// stay open, and training does not.
// Reports are included: a lapsed member keeps read access to their own
// history, which is the point of a lapse not being a sign-out.
const _lapsedAllowed = {
  '/renew',
  '/profile',
  '/profile/edit',
  '/reports',
  '/notices',
  '/plan/history',
};

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
          final isAdminRoute = path.startsWith('/admin');
          final isStaff = value?.role.isStaff ?? false;

          // Staff land on the dashboard; a member who types an /admin
          // URL is sent back. This is convenience, not security: the
          // Firestore rules are what actually stop them, because hiding
          // a screen does nothing against the SDK and a token.
          if (isAdminRoute && !isStaff) return '/';
          if (isStaff && !isAdminRoute) return '/admin/members';

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
      // The five member tabs live inside the shell, so the bottom bar
      // stays put as they are switched. Screens pushed on top of a tab —
      // an exercise, an event — cover it, as the designs show.
      ShellRoute(
        builder: (context, state, child) =>
            MemberShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) => const PlanScreen(),
          ),
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/plan/exercise',
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: '/plan/history',
        builder: (context, state) => const PlanHistoryScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/admin/members',
            builder: (context, state) => const AdminMembersScreen(),
          ),
          GoRoute(
            path: '/admin/exercises',
            builder: (context, state) => const AdminExercisesScreen(),
          ),
          GoRoute(
            path: '/admin/plans',
            builder: (context, state) => const AdminPlansScreen(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (context, state) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '/admin/classes',
            builder: (context, state) => const AdminClassesScreen(),
          ),
          GoRoute(
            path: '/admin/announcements',
            builder: (context, state) => const AdminAnnouncementsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/classes/:classId',
        builder: (context, state) =>
            ClassDetailScreen(classId: state.pathParameters['classId']!),
      ),
      GoRoute(
        path: '/notices',
        builder: (context, state) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportScreen(),
      ),
    ],
  );
});
