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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _progress;
  bool _minimumWaitDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: .96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _progress = Tween<double>(begin: 0, end: .72).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    Future<void>.delayed(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      _minimumWaitDone = true;
      _goNext(ref.read(authControllerProvider));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
      backgroundColor: AppColors.white,
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
              border: Border.all(color: const Color(0xFFF2EEE4)),
            ),
          ),
          Container(
            width: 172,
            height: 172,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFAF6ED).withValues(alpha: .84),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldBright.withValues(alpha: .08),
                  blurRadius: 34,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Positioned(left: 58, top: 134, child: _Sparkle(size: 20)),
          Positioned(right: 62, top: 124, child: _Sparkle(size: 18)),
          Image.asset(
            'assets/logo2.png',
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
      color: const Color(0xFFD7C9A7).withValues(alpha: .64),
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
      color: AppColors.black,
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
              style: TextStyle(color: Color(0xFFD2A83D)),
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
          backgroundColor: const Color(0xFFE9E7E4),
          color: AppColors.goldBright,
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
              const Color(0xFFF8EBCB).withValues(alpha: .28),
              AppColors.white.withValues(alpha: 0),
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
      color: const Color(0xFFF3EAD8).withValues(alpha: .48),
    );
    _drawWave(
      canvas,
      size,
      y: size.height * .88,
      height: 42,
      color: const Color(0xFFF8F1E5).withValues(alpha: .66),
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
