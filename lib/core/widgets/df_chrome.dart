import 'dart:math' as math;

import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';

/// The app bar used across the member screens: the wordmark on the left,
/// notices and the member's avatar on the right.
class DfBrandBar extends StatelessWidget implements PreferredSizeWidget {
  const DfBrandBar({
    super.key,
    this.photoUrl,
    this.onNotices,
    this.onProfile,
  });

  final String? photoUrl;
  final VoidCallback? onNotices;
  final VoidCallback? onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: AppColors.surfaceContainerLowest,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              'D',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEEP FITNESS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'MYSORE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onNotices,
          tooltip: 'Notices',
          icon: const Icon(Icons.notifications_none),
        ),
        GestureDetector(
          onTap: onProfile,
          child: Padding(
            padding: const EdgeInsets.only(right: Insets.md, left: Insets.xs),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceContainerHigh,
              backgroundImage: photoUrl == null
                  ? null
                  : NetworkImage(photoUrl!),
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A flat telemetry ring: a 1px-to-4px track, a solid accent arc, and the
/// percentage in the middle. No caps, no glow — the system is explicit.
class DfProgressRing extends StatelessWidget {
  const DfProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.stroke = 6,
    this.label,
  });

  /// 0 to 1.
  final double value;
  final double size;
  final double stroke;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value: value.clamp(0, 1), stroke: stroke),
        child: Center(
          child: Text(
            label ?? '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.stroke});

  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceContainerHigh;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      // Butt, not round: the design system asks for no stroke caps.
      ..strokeCap = StrokeCap.butt
      ..color = AppColors.primaryContainer;

    canvas.drawCircle(centre, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.stroke != stroke;
}

/// A flat progress bar, matching the ring's track and fill.
class DfProgressBar extends StatelessWidget {
  const DfProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.surfaceContainerHigh,
        valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
      ),
    );
  }
}
