import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return PremiumScaffold(
      bottomPadding: 176,
      child: AsyncStateView(
        value: progress,
        errorTitle: 'Could not load your progress',
        onRetry: () => ref.invalidate(progressProvider),
        data: (progress) => _ProgressContent(progress: progress),
      ),
    );
  }
}

class _ProgressContent extends ConsumerWidget {
  const _ProgressContent({required this.progress});

  final MemberProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(progressDateRangeProvider);
    final rangeLabel = selectedRange == null
        ? 'This month'
        : '${_formatShortDate(selectedRange.start)} - ${_formatShortDate(selectedRange.end)}';
    final deltaPrefix = progress.weightDelta > 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Progress',
          subtitle: rangeLabel,
          action: IconButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now,
                initialDateRange: selectedRange == null
                    ? DateTimeRange(
                        start: DateTime(now.year, now.month, 1),
                        end: now,
                      )
                    : DateTimeRange(
                        start: selectedRange.start,
                        end: selectedRange.end,
                      ),
              );
              if (picked == null) return;
              ref
                  .read(progressDateRangeProvider.notifier)
                  .select(picked.start, picked.end);
            },
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _BodyVisualCard(progress: progress),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: '${progress.currentWeight.toStringAsFixed(1)} kg',
                caption:
                    '$deltaPrefix${progress.weightDelta.toStringAsFixed(1)} kg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.fitness_center_rounded,
                label: 'Workouts',
                value: '${progress.workoutsCompleted}',
                caption: 'completed',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Adherence',
                value: '${(progress.adherence * 100).round()}%',
                caption: '${progress.completedExercises} done',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.error_outline_rounded,
                label: 'Missed',
                value: '${progress.missedExercises}',
                caption: '${progress.assignedExercises} assigned',
                danger: progress.missedExercises > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _MuscleBarCard(
          title: 'Muscle Progress',
          onTap: () => context.push('/progress/muscles'),
          muscles: progress.muscleProgress,
        ),
        const SizedBox(height: 18),
        _BestStripCard(
          title: 'Personal Bests',
          onTap: () => context.push('/progress/bests'),
          bests: progress.personalBests,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BodyVisualCard extends StatelessWidget {
  const _BodyVisualCard({required this.progress});

  final MemberProgress progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: CustomPaint(
        painter: _MuscleBodyPainter(
          isFemale: progress.gender == 'female',
          muscleProgress: progress.muscleProgress,
          outlineColor: AppColors.secondaryText(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF5A2C) : AppColors.gold;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.secondaryText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: danger ? color : AppColors.secondaryText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleBarCard extends StatelessWidget {
  const _MuscleBarCard({
    required this.title,
    required this.muscles,
    required this.onTap,
  });

  final String title;
  final Map<String, int> muscles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entries = _displayMuscles(muscles).take(8).toList();
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _SectionHeader(title: title, onTap: onTap),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _EmptyInline(
              message: 'Complete workouts to build muscle group history.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth = (constraints.maxWidth - 18) / 2;
                return Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: columnWidth,
                        child: _MuscleBar(
                          label: entry.key,
                          value: entry.value,
                          color: _muscleColor(entry.key),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BestStripCard extends StatelessWidget {
  const _BestStripCard({
    required this.title,
    required this.bests,
    required this.onTap,
  });

  final String title;
  final Map<String, int> bests;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entries = bests.entries.take(4).toList();
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _SectionHeader(title: title, onTap: onTap),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            _EmptyInline(message: 'Log weighted sets to unlock personal bests.')
          else
            Row(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  Expanded(child: _BestMini(entry: entries[i])),
                  if (i != entries.length - 1)
                    Container(
                      width: 1,
                      height: 58,
                      color: AppColors.divider(context),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondaryText(context),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
        ],
      ),
    );
  }
}

class _MuscleBar extends StatelessWidget {
  const _MuscleBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          height: 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              backgroundColor: AppColors.divider(context),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+$value%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BestMini extends StatelessWidget {
  const _BestMini({required this.entry});

  final MapEntry<String, int> entry;

  @override
  Widget build(BuildContext context) {
    final color = _muscleColor(entry.key);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(width: 26, height: 3, color: color),
          const SizedBox(height: 10),
          Text(
            entry.key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText(context),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.value} kg',
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.insights_rounded, color: AppColors.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryText(context),
            ),
          ),
        ),
      ],
    );
  }
}

class MuscleProgressDetailScreen extends ConsumerWidget {
  const MuscleProgressDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return PremiumScaffold(
      bottomPadding: 176,
      child: AsyncStateView(
        value: progress,
        errorTitle: 'Could not load muscle progress',
        onRetry: () => ref.invalidate(progressProvider),
        data: (progress) => _ProgressDetailContent(
          title: 'Muscle Progress',
          subtitle: 'Main muscle groups from completed sets.',
          emptyMessage: 'Complete workouts to build muscle group history.',
          items: progress.muscleProgress.entries
              .map(
                (entry) => _ProgressItem(
                  icon: progressMuscleIcon(entry.key),
                  label: entry.key,
                  value: '+${entry.value}%',
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class PersonalBestsDetailScreen extends ConsumerWidget {
  const PersonalBestsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return PremiumScaffold(
      bottomPadding: 176,
      child: AsyncStateView(
        value: progress,
        errorTitle: 'Could not load personal bests',
        onRetry: () => ref.invalidate(progressProvider),
        data: (progress) => _ProgressDetailContent(
          title: 'Personal Bests',
          subtitle: 'Highest weight logged for weighted exercises.',
          emptyMessage: 'Log weighted sets to unlock personal bests.',
          items: progress.personalBests.entries
              .map(
                (entry) => _ProgressItem(
                  icon: progressBestIcon(entry.key),
                  label: entry.key,
                  value: '${entry.value} kg',
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProgressDetailContent extends StatelessWidget {
  const _ProgressDetailContent({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<_ProgressItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: title,
          subtitle: subtitle,
          action: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ProgressGridCard(
          title: 'All',
          emptyMessage: emptyMessage,
          items: items,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class _ProgressItem {
  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProgressGridCard extends StatelessWidget {
  const _ProgressGridCard({
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<_ProgressItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryText(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleItems.isEmpty)
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                ),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in visibleItems)
                      SizedBox(
                        width: tileWidth,
                        child: _Metric(item: item),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

IconData progressMuscleIcon(String key) {
  return switch (key) {
    'Chest' => Icons.favorite_border_rounded,
    'Back' => Icons.accessibility_new_rounded,
    'Legs' => Icons.directions_walk_rounded,
    'Shoulders' => Icons.fitness_center_rounded,
    'Arms' => Icons.sports_mma_rounded,
    'Core' => Icons.self_improvement_rounded,
    'Cardio' => Icons.directions_run_rounded,
    _ => Icons.fitness_center_rounded,
  };
}

IconData progressBestIcon(String key) {
  final name = key.toLowerCase();
  if (name.contains('squat') ||
      name.contains('leg') ||
      name.contains('lunge')) {
    return Icons.directions_walk_rounded;
  }
  if (name.contains('row') ||
      name.contains('pull') ||
      name.contains('deadlift')) {
    return Icons.fitness_center_rounded;
  }
  if (name.contains('press') ||
      name.contains('chest') ||
      name.contains('bench')) {
    return Icons.trending_up_rounded;
  }
  if (name.contains('curl') || name.contains('tricep')) {
    return Icons.sports_mma_rounded;
  }
  return Icons.emoji_events_outlined;
}

List<MapEntry<String, int>> _displayMuscles(Map<String, int> muscles) {
  const order = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Core',
    'Legs',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Cardio',
  ];
  final entries = <MapEntry<String, int>>[];
  for (final key in order) {
    final value = muscles[key];
    if (value != null) entries.add(MapEntry(key, value));
  }
  for (final entry in muscles.entries) {
    if (!entries.any((item) => item.key == entry.key)) entries.add(entry);
  }
  return entries;
}

Color _muscleColor(String key) {
  final normalized = key.toLowerCase();
  if (normalized.contains('chest')) return const Color(0xFFFF512F);
  if (normalized.contains('back')) return const Color(0xFF13A88B);
  if (normalized.contains('shoulder')) return const Color(0xFFF5BA00);
  if (normalized.contains('arm') ||
      normalized.contains('bicep') ||
      normalized.contains('tricep')) {
    return const Color(0xFF8C4DE8);
  }
  if (normalized.contains('core') || normalized.contains('ab')) {
    return const Color(0xFF62C83F);
  }
  if (normalized.contains('hamstring')) return const Color(0xFFFF5A2C);
  if (normalized.contains('glute')) return const Color(0xFFF0448B);
  if (normalized.contains('calf')) return const Color(0xFF11A786);
  if (normalized.contains('leg') || normalized.contains('quad')) {
    return const Color(0xFF2382F6);
  }
  if (normalized.contains('cardio')) return const Color(0xFFFF8E1A);
  return AppColors.gold;
}

class _MuscleBodyPainter extends CustomPainter {
  const _MuscleBodyPainter({
    required this.isFemale,
    required this.muscleProgress,
    required this.outlineColor,
  });

  final bool isFemale;
  final Map<String, int> muscleProgress;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = outlineColor.withValues(alpha: .62);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: .12);

    canvas.drawCircle(
      Offset(size.width * .50, size.height * .52),
      size.width * .42,
      faint,
    );

    _drawFigure(
      canvas,
      Rect.fromLTWH(0, 14, size.width * .48, size.height - 28),
      front: true,
      outline: outline,
    );
    _drawFigure(
      canvas,
      Rect.fromLTWH(size.width * .52, 14, size.width * .48, size.height - 28),
      front: false,
      outline: outline,
    );
  }

  void _drawFigure(
    Canvas canvas,
    Rect rect, {
    required bool front,
    required Paint outline,
  }) {
    final cx = rect.center.dx;
    final top = rect.top;
    final h = rect.height;
    final w = rect.width;
    final shoulder = isFemale ? w * .24 : w * .28;
    final hip = isFemale ? w * .20 : w * .16;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, top + h * .075),
        width: w * .15,
        height: h * .13,
      ),
      outline,
    );
    canvas.drawLine(
      Offset(cx, top + h * .14),
      Offset(cx, top + h * .63),
      outline,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - shoulder, top + h * .19)
        ..quadraticBezierTo(cx, top + h * .13, cx + shoulder, top + h * .19)
        ..lineTo(cx + hip, top + h * .52)
        ..quadraticBezierTo(cx, top + h * .60, cx - hip, top + h * .52)
        ..close(),
      outline,
    );
    canvas.drawLine(
      Offset(cx - shoulder, top + h * .20),
      Offset(cx - w * .34, top + h * .48),
      outline,
    );
    canvas.drawLine(
      Offset(cx + shoulder, top + h * .20),
      Offset(cx + w * .34, top + h * .48),
      outline,
    );
    canvas.drawLine(
      Offset(cx - hip * .72, top + h * .56),
      Offset(cx - w * .13, top + h * .94),
      outline,
    );
    canvas.drawLine(
      Offset(cx + hip * .72, top + h * .56),
      Offset(cx + w * .13, top + h * .94),
      outline,
    );

    if (front) {
      _muscle(canvas, rect, 'Chest', cx - w * .075, .25, .16, .07);
      _muscle(canvas, rect, 'Chest', cx + w * .075, .25, .16, .07);
      _muscle(canvas, rect, 'Shoulders', cx - w * .20, .25, .08, .10);
      _muscle(canvas, rect, 'Shoulders', cx + w * .20, .25, .08, .10);
      _muscle(canvas, rect, 'Arms', cx - w * .27, .37, .07, .16);
      _muscle(canvas, rect, 'Arms', cx + w * .27, .37, .07, .16);
      for (final y in [.35, .42, .49]) {
        _muscle(canvas, rect, 'Core', cx - w * .045, y, .055, .055);
        _muscle(canvas, rect, 'Core', cx + w * .045, y, .055, .055);
      }
      _muscle(canvas, rect, 'Legs', cx - w * .09, .69, .09, .25);
      _muscle(canvas, rect, 'Legs', cx + w * .09, .69, .09, .25);
      _muscle(canvas, rect, 'Calves', cx - w * .08, .88, .055, .12);
      _muscle(canvas, rect, 'Calves', cx + w * .08, .88, .055, .12);
    } else {
      _muscle(canvas, rect, 'Back', cx, .31, .25, .23);
      _muscle(canvas, rect, 'Shoulders', cx - w * .21, .27, .075, .10);
      _muscle(canvas, rect, 'Shoulders', cx + w * .21, .27, .075, .10);
      _muscle(canvas, rect, 'Arms', cx - w * .27, .40, .065, .15);
      _muscle(canvas, rect, 'Arms', cx + w * .27, .40, .065, .15);
      _muscle(canvas, rect, 'Glutes', cx - w * .075, .57, .12, .10);
      _muscle(canvas, rect, 'Glutes', cx + w * .075, .57, .12, .10);
      _muscle(canvas, rect, 'Hamstrings', cx - w * .09, .73, .07, .22);
      _muscle(canvas, rect, 'Hamstrings', cx + w * .09, .73, .07, .22);
      _muscle(canvas, rect, 'Calves', cx - w * .08, .89, .055, .12);
      _muscle(canvas, rect, 'Calves', cx + w * .08, .89, .055, .12);
    }
  }

  void _muscle(
    Canvas canvas,
    Rect rect,
    String muscle,
    double centerX,
    double yFactor,
    double widthFactor,
    double heightFactor,
  ) {
    final value = ((muscleProgress[muscle] ?? 0) / 100).clamp(0.22, 1.0);
    final color = _muscleColor(muscle).withValues(alpha: value);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, rect.top + rect.height * yFactor),
          width: rect.width * widthFactor,
          height: rect.height * heightFactor,
        ),
        const Radius.circular(999),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MuscleBodyPainter oldDelegate) {
    return oldDelegate.isFemale != isFemale ||
        oldDelegate.muscleProgress != muscleProgress ||
        oldDelegate.outlineColor != outlineColor;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.item});

  final _ProgressItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: AppColors.gold, size: 24),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText(context),
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}
