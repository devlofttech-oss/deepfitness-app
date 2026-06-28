import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _minimumSplashDone = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slide = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _minimumSplashDone = true;
      _goNext(ref.read(authControllerProvider));
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSessionState>>(authControllerProvider, (
      previous,
      next,
    ) {
      _goNext(next);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = .10 + (_pulseController.value * .10);
                      return Transform.scale(
                        scale: _scale.value,
                        child: Container(
                          width: 188,
                          height: 188,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldBright.withValues(
                                  alpha: pulse,
                                ),
                                blurRadius: 38,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: .06),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: const BrandMark(size: 172),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                      children: const [
                        TextSpan(
                          text: 'DEEP ',
                          style: TextStyle(color: AppColors.black),
                        ),
                        TextSpan(
                          text: 'FITNESS',
                          style: TextStyle(color: AppColors.goldBright),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing your plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      width: 168,
                      height: 4,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.border,
                        color: AppColors.goldBright,
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goNext(AsyncValue<AuthSessionState> authState) {
    if (!mounted || !_minimumSplashDone) return;
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
