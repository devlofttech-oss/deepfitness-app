import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
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
  late final AnimationController _progressController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _progress;
  bool _minimumWaitDone = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _scale = Tween<double>(begin: .96, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _progress = Tween<double>(begin: 0, end: .72).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      _progressController.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 1750), () {
      if (!mounted) return;
      _minimumWaitDone = true;
      _goNext(ref.read(authControllerProvider));
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession>>(authControllerProvider, (
      previous,
      next,
    ) {
      _goNext(next);
    });

    // Signed in goes to the app, signed out goes to sign-in, so the splash
    // shows the artwork for wherever it is about to land: the logo on the way
    // to the login page, the hero on the way into the app itself.
    final session = ref.watch(authControllerProvider).value;
    final returning = session?.isSignedIn ?? false;

    if (returning) return _HeroSplash(fade: _fade);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _SplashBackgroundPainter()),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    const _LogoOrb(),
                    const SizedBox(height: 44),
                    const _BrandWordmark(),
                    const SizedBox(height: 24),
                    Text(
                      'Ready to level up?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF9F9F9F),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) =>
                          _LoadingBar(value: _progress.value),
                    ),
                    const Spacer(flex: 7),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Leaves the splash once the minimum wait has passed and the session has
  /// resolved. Where it goes is the router's decision, not this screen's:
  /// pushing at the root lets the redirect guard place it.
  void _goNext(AsyncValue<AuthSession> authState) {
    if (!mounted || !_minimumWaitDone) return;
    if (authState.isLoading && !authState.hasValue) return;
    context.go(authState.hasError ? '/sign-in' : '/');
  }
}

/// The splash a signed-in member sees on the way back into the app.
///
/// Full bleed rather than a framed logo: this one is a photograph, and a
/// scrim top and bottom keeps it from fighting the status bar or the first
/// frame of the app underneath.
class _HeroSplash extends StatelessWidget {
  const _HeroSplash({required this.fade});

  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FadeTransition(
        opacity: fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: .55),
                    AppColors.surface.withValues(alpha: .10),
                    AppColors.surface.withValues(alpha: .92),
                  ],
                  stops: const [0, .45, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 310,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
          ),
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLow.withValues(alpha: .84),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: .18),
                  blurRadius: 34,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Positioned(left: 58, top: 134, child: _Sparkle(size: 20)),
          Positioned(right: 62, top: 124, child: _Sparkle(size: 18)),
          Image.asset(
            'assets/logo.png',
            width: 164,
            height: 164,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: AppColors.primaryContainer.withValues(alpha: .52),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 10,
      color: AppColors.onSurface,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RichText(
        text: TextSpan(
          style: style,
          children: const [
            TextSpan(text: 'DEEP '),
            TextSpan(
              text: 'FITNESS',
              style: TextStyle(color: AppColors.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        width: 188,
        height: 6,
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.surfaceContainerHigh,
          color: AppColors.primaryContainer,
          minHeight: 6,
        ),
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.primaryContainer.withValues(alpha: .12),
              AppColors.surface.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .50, size.height * .42),
              radius: size.width * .62,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * .50, size.height * .42),
      size.width * .62,
      topGlow,
    );

    _drawWave(
      canvas,
      size,
      y: size.height * .82,
      height: 56,
      color: AppColors.surfaceContainerLow.withValues(alpha: .55),
    );
    _drawWave(
      canvas,
      size,
      y: size.height * .88,
      height: 42,
      color: AppColors.surfaceContainerHigh.withValues(alpha: .75),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double y,
    required double height,
    required Color color,
  }) {
    final path = Path()
      ..moveTo(0, y)
      ..cubicTo(
        size.width * .22,
        y - height,
        size.width * .42,
        y + height,
        size.width * .62,
        y,
      )
      ..cubicTo(
        size.width * .78,
        y - height * .75,
        size.width * .9,
        y + height * .55,
        size.width,
        y - height * .18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
