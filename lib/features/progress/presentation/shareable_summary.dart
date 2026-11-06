import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the summary card to a PNG and hands it to the share sheet.
///
/// The guide asks for an image rendered from the widget tree rather than a
/// block of text: a screenshot of their own numbers is the thing a member
/// actually posts.
Future<void> shareProgressSummary({
  required GlobalKey boundaryKey,
  required String memberName,
}) async {
  final bytes = await captureSummary(boundaryKey);
  if (bytes == null) {
    throw StateError('The summary could not be rendered just now.');
  }

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'deep-fitness-progress.png',
        ),
      ],
      subject: '$memberName at Deep Fitness',
    ),
  );
}

/// Pulls the PNG bytes out of the boundary [key] wraps.
///
/// Returns null when the boundary has not been laid out yet, which happens if
/// the card is off-screen or the first frame has not run.
Future<Uint8List?> captureSummary(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final object = key.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;

  // A boundary still mid-paint would capture a blank frame.
  if (object.debugNeedsPaint) {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (object.debugNeedsPaint) return null;
  }

  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// The card that gets rendered. Deliberately self-contained: it must read the
/// same whether it is on screen or saved to someone's camera roll, so nothing
/// in it depends on the surrounding scroll position or theme brightness.
class ShareableSummary extends StatelessWidget {
  const ShareableSummary({
    super.key,
    required this.boundaryKey,
    required this.memberName,
    required this.progress,
    required this.rangeLabel,
  });

  final GlobalKey boundaryKey;
  final String memberName;
  final MemberProgress progress;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.night,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              memberName,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rangeLabel,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: .62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _Stat(
                  value: '${progress.completedExercises}',
                  label: 'Exercises',
                ),
                _Stat(value: '${progress.dayStreak}', label: 'Day streak'),
                _Stat(
                  value: '${(progress.adherence * 100).round()}%',
                  label: 'Adherence',
                ),
              ],
            ),
            if (progress.personalBests.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Personal bests',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 8),
              for (final best in progress.personalBests.entries.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          best.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${best.value} kg',
                        style: const TextStyle(
                          color: AppColors.goldBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 22),
            Text(
              'Deep Fitness',
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: .8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.goldBright,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .62),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
