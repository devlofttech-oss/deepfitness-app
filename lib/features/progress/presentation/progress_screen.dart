import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/progress_ring.dart';
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
        const SizedBox(height: 28),
        PremiumCard(
          padding: const EdgeInsets.all(26),
          child: Row(
            children: [
              const IconTile(icon: Icons.monitor_weight_outlined),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondaryText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          progress.currentWeight.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9, left: 8),
                          child: Text(
                            'kg',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.secondaryText(context),
                                ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$deltaPrefix${progress.weightDelta.toStringAsFixed(1)} kg  this month',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const IconTile(icon: Icons.trending_up_rounded, size: 66),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PremiumCard(
          padding: const EdgeInsets.all(26),
          child: Row(
            children: [
              const IconTile(icon: Icons.fitness_center_rounded),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workouts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondaryText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${progress.workoutsCompleted}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      'total completed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(value: progress.goalCompletion, size: 86),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProgressGridCard(
          title: 'Muscle Progress',
          emptyMessage: 'Complete workouts to build muscle group history.',
          previewCount: 2,
          onTap: () => context.push('/progress/muscles'),
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
        const SizedBox(height: 24),
        _ProgressGridCard(
          title: 'Personal Bests',
          emptyMessage: 'Log weighted sets to unlock personal bests.',
          previewCount: 2,
          onTap: () => context.push('/progress/bests'),
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
        const SizedBox(height: 24),
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
    this.previewCount,
    this.onTap,
  });

  final String title;
  final List<_ProgressItem> items;
  final String emptyMessage;
  final int? previewCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visibleItems = previewCount == null
        ? items
        : items.take(previewCount!).toList();
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gold,
                    size: 24,
                  ),
              ],
            ),
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
