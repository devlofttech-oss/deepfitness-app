import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/presentation/login_screen.dart';
import 'package:deepfitness/features/diet/presentation/diet_screen.dart';
import 'package:deepfitness/features/home/presentation/member_shell.dart';
import 'package:deepfitness/features/home/presentation/today_screen.dart';
import 'package:deepfitness/features/profile/presentation/profile_screen.dart';
import 'package:deepfitness/features/progress/presentation/progress_screen.dart';
import 'package:deepfitness/features/splash/presentation/splash_screen.dart';
import 'package:deepfitness/features/trainer/presentation/trainer_screens.dart';
import 'package:deepfitness/features/workout/presentation/exercise_logging_screen.dart';
import 'package:deepfitness/features/workout/presentation/workout_detail_screen.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider).value;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isSplash = state.uri.path == '/splash';
      final isAuthRoute = {
        '/login',
        '/register',
        '/trainer-login',
      }.contains(state.uri.path);
      final isTrainerRoute = state.uri.path.startsWith('/trainer');
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final role = authState?.role;

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return role == UserRole.trainer ? '/trainer' : '/';
      }

      if (isAuthenticated && role == UserRole.trainer && !isTrainerRoute) {
        return '/trainer';
      }

      if (isAuthenticated && role == UserRole.member && isTrainerRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _smoothPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _smoothPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _smoothPage(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/trainer-login',
        pageBuilder: (context, state) =>
            _smoothPage(state: state, child: const TrainerLoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MemberShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _smoothPage(state: state, child: const TodayScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) =>
                _smoothPage(state: state, child: const ProgressScreen()),
          ),
          GoRoute(
            path: '/diet',
            pageBuilder: (context, state) =>
                _smoothPage(state: state, child: const DietScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _smoothPage(state: state, child: const ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/workout',
        pageBuilder: (context, state) => _smoothPage(
          state: state,
          child: const _RoleGuard(
            role: UserRole.member,
            fallbackRoute: '/login',
            child: WorkoutDetailScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/exercise-preview',
        pageBuilder: (context, state) => _smoothPage(
          state: state,
          child: const _RoleGuard(
            role: UserRole.member,
            fallbackRoute: '/login',
            child: ExercisePreviewScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/exercise-log',
        pageBuilder: (context, state) => _smoothPage(
          state: state,
          child: const _RoleGuard(
            role: UserRole.member,
            fallbackRoute: '/login',
            child: ExerciseLoggingScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/workout-complete',
        pageBuilder: (context, state) => _smoothPage(
          state: state,
          child: const _RoleGuard(
            role: UserRole.member,
            fallbackRoute: '/login',
            child: WorkoutCompletionScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/trainer',
        pageBuilder: (context, state) =>
            _trainerPage(state, const TrainerDashboardScreen()),
      ),
      GoRoute(
        path: '/trainer/members',
        pageBuilder: (context, state) =>
            _trainerPage(state, const MembersListScreen()),
      ),
      GoRoute(
        path: '/trainer/members/add',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AddMemberScreen()),
      ),
      GoRoute(
        path: '/trainer/member',
        pageBuilder: (context, state) =>
            _trainerPage(state, const MemberDetailScreen()),
      ),
      GoRoute(
        path: '/trainer/workout-plan',
        pageBuilder: (context, state) =>
            _trainerPage(state, const CreateWorkoutPlanScreen()),
      ),
      GoRoute(
        path: '/trainer/exercises',
        pageBuilder: (context, state) =>
            _trainerPage(state, const ExerciseLibraryScreen()),
      ),
      GoRoute(
        path: '/trainer/diet-plan',
        pageBuilder: (context, state) =>
            _trainerPage(state, const CreateDietPlanScreen()),
      ),
      GoRoute(
        path: '/trainer/assign',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignPlanScreen()),
      ),
      GoRoute(
        path: '/trainer/assign/member',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignMemberScreen()),
      ),
      GoRoute(
        path: '/trainer/assign/source',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignSourceScreen()),
      ),
      GoRoute(
        path: '/trainer/assign/saved',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignSavedPlanScreen()),
      ),
      GoRoute(
        path: '/trainer/assign/exercises',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignExercisesScreen()),
      ),
      GoRoute(
        path: '/trainer/assign/meals',
        pageBuilder: (context, state) =>
            _trainerPage(state, const AssignMealsScreen()),
      ),
      GoRoute(
        path: '/trainer/profile',
        pageBuilder: (context, state) =>
            _trainerPage(state, const TrainerProfileScreen()),
      ),
    ],
  );
});

CustomTransitionPage<void> _trainerPage(GoRouterState state, Widget child) {
  return _smoothPage(
    state: state,
    child: _RoleGuard(
      role: UserRole.trainer,
      fallbackRoute: '/trainer-login',
      child: child,
    ),
  );
}

CustomTransitionPage<void> _smoothPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 210),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.035, .02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _RoleGuard extends ConsumerWidget {
  const _RoleGuard({
    required this.role,
    required this.fallbackRoute,
    required this.child,
  });

  final UserRole role;
  final String fallbackRoute;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.maybeWhen(data: (value) => value, orElse: () => null);
    if (session?.isAuthenticated != true || session?.role != role) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(fallbackRoute);
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
