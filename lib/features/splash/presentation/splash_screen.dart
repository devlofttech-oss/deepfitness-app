import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumWaitDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _minimumWaitDone = true;
      _goNext(ref.read(authControllerProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSessionState>>(authControllerProvider, (
      previous,
      next,
    ) {
      _goNext(next);
    });

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(),
    );
  }

  void _goNext(AsyncValue<AuthSessionState> authState) {
    if (!mounted || !_minimumWaitDone) return;
    final session = authState.value;
    if (authState.hasError) {
      context.go('/login');
      return;
    }
    if (session == null) return;
    if (!session.isAuthenticated) {
      context.go('/login');
      return;
    }
    context.go(session.role == UserRole.trainer ? '/trainer' : '/');
  }
}
