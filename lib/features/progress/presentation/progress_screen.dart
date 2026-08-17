import 'dart:math' as math;

import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

const _bodyVisualHeight = 362.0;
const _bodyVisualScale = 1.13;

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

class _BodyVisualCard extends StatefulWidget {
  const _BodyVisualCard({required this.progress});

  final MemberProgress progress;

  @override
  State<_BodyVisualCard> createState() => _BodyVisualCardState();
}

class _BodyVisualCardState extends State<_BodyVisualCard> {
  String? _selectedLayer;

  @override
  Widget build(BuildContext context) {
    final gender = widget.progress.gender?.toLowerCase() == 'female'
        ? 'female'
        : 'male';
    final metrics = _BodySvgMetrics.forGender(gender);
    final selected = _selectedLayer == null
        ? null
        : _bodyLayerForAsset(_selectedLayer!);
    final selectedValue = selected == null
        ? null
        : _progressForLayer(widget.progress.muscleProgress, selected);

    return SizedBox(
      height: _bodyVisualHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final layer = _hitTestBodyLayer(
                details.localPosition,
                Size(constraints.maxWidth, constraints.maxHeight),
                metrics,
              );
              if (layer == null) return;
              setState(() {
                _selectedLayer = _selectedLayer == layer ? null : layer;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: .16),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform.scale(
                    scale: _bodyVisualScale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: .82,
                            child: SvgPicture.asset(
                              'assets/body/$gender/front_outline.svg',
                              fit: BoxFit.contain,
                              clipBehavior: Clip.none,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: .82,
                            child: SvgPicture.asset(
                              'assets/body/$gender/back_outline.svg',
                              fit: BoxFit.contain,
                              clipBehavior: Clip.none,
                            ),
                          ),
                        ),
                        for (final layer in _bodyLayers)
                          Positioned.fill(
                            child: _AnimatedBodyLayer(
                              assetPath:
                                  'assets/body/$gender/${layer.assetName}.svg',
                              color: _bodyLayerColor(layer.assetName),
                              progress:
                                  _progressForLayer(
                                    widget.progress.muscleProgress,
                                    layer,
                                  ) /
                                  100,
                              selected: _selectedLayer == layer.assetName,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected == null
                        ? const SizedBox(height: 36)
                        : Align(
                            key: ValueKey(selected.assetName),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: .42),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: AppColors.isDark(context)
                                          ? .32
                                          : .06,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${selected.label} +${selectedValue ?? 0}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.text(context),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedBodyLayer extends StatelessWidget {
  const _AnimatedBodyLayer({
    required this.assetPath,
    required this.color,
    required this.progress,
    required this.selected,
  });

  final String assetPath;
  final Color color;
  final double progress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final targetProgress = progress.clamp(0.0, 1.0);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetProgress),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, child) {
          final opacity = selected
              ? .98
              : (animatedProgress == 0
                    ? .18
                    : (.34 + animatedProgress * .58).clamp(.34, .92));
          final layerColor = selected ? AppColors.gold : color;
          return AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(layerColor, BlendMode.srcIn),
              child: child,
            ),
          );
        },
        child: SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
          clipBehavior: Clip.none,
        ),
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

class _BodyLayerDefinition {
  const _BodyLayerDefinition({
    required this.assetName,
    required this.label,
    required this.progressKeys,
  });

  final String assetName;
  final String label;
  final List<String> progressKeys;
}

class _BodySvgMetrics {
  const _BodySvgMetrics({
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.bodyWidth,
    required this.backStart,
  });

  final double viewBoxWidth;
  final double viewBoxHeight;
  final double bodyWidth;
  final double backStart;

  static _BodySvgMetrics forGender(String gender) {
    if (gender == 'female') {
      return const _BodySvgMetrics(
        viewBoxWidth: 1256,
        viewBoxHeight: 1450,
        bodyWidth: 650,
        backStart: 606,
      );
    }
    return const _BodySvgMetrics(
      viewBoxWidth: 1410,
      viewBoxHeight: 1280,
      bodyWidth: 727,
      backStart: 683,
    );
  }
}

const _bodyLayers = <_BodyLayerDefinition>[
  _BodyLayerDefinition(
    assetName: 'chest',
    label: 'Chest',
    progressKeys: ['Chest'],
  ),
  _BodyLayerDefinition(
    assetName: 'shoulders',
    label: 'Shoulders',
    progressKeys: ['Shoulders'],
  ),
  _BodyLayerDefinition(
    assetName: 'arms',
    label: 'Arms',
    progressKeys: ['Arms', 'Biceps', 'Triceps'],
  ),
  _BodyLayerDefinition(
    assetName: 'forearms',
    label: 'Forearms',
    progressKeys: ['Forearms', 'Arms'],
  ),
  _BodyLayerDefinition(
    assetName: 'abs',
    label: 'Abs',
    progressKeys: ['Abs', 'Core'],
  ),
  _BodyLayerDefinition(
    assetName: 'obliques',
    label: 'Obliques',
    progressKeys: ['Obliques', 'Core'],
  ),
  _BodyLayerDefinition(
    assetName: 'lats',
    label: 'Lats',
    progressKeys: ['Lats', 'Back'],
  ),
  _BodyLayerDefinition(
    assetName: 'traps',
    label: 'Traps',
    progressKeys: ['Traps', 'Back', 'Shoulders'],
  ),
  _BodyLayerDefinition(
    assetName: 'quads',
    label: 'Quads',
    progressKeys: ['Quads', 'Legs'],
  ),
  _BodyLayerDefinition(
    assetName: 'hamstrings',
    label: 'Hamstrings',
    progressKeys: ['Hamstrings', 'Legs'],
  ),
  _BodyLayerDefinition(
    assetName: 'glutes',
    label: 'Glutes',
    progressKeys: ['Glutes', 'Legs'],
  ),
  _BodyLayerDefinition(
    assetName: 'calves',
    label: 'Calves',
    progressKeys: ['Calves', 'Legs'],
  ),
];

_BodyLayerDefinition? _bodyLayerForAsset(String assetName) {
  for (final layer in _bodyLayers) {
    if (layer.assetName == assetName) return layer;
  }
  return null;
}

int _progressForLayer(
  Map<String, int> muscleProgress,
  _BodyLayerDefinition layer,
) {
  for (final key in layer.progressKeys) {
    final value = _progressValue(muscleProgress, key);
    if (value != null) return value;
  }
  return 0;
}

int? _progressValue(Map<String, int> muscleProgress, String key) {
  final direct = muscleProgress[key];
  if (direct != null) return direct;
  final normalizedKey = key.toLowerCase();
  for (final entry in muscleProgress.entries) {
    if (entry.key.toLowerCase() == normalizedKey) return entry.value;
  }
  return null;
}

String? _hitTestBodyLayer(
  Offset position,
  Size boxSize,
  _BodySvgMetrics metrics,
) {
  final center = Offset(boxSize.width / 2, boxSize.height / 2);
  final unscaledPosition = center + (position - center) / _bodyVisualScale;
  final paintRect = _svgPaintRect(boxSize, metrics);
  if (!paintRect.contains(unscaledPosition)) return null;

  final svgX =
      ((unscaledPosition.dx - paintRect.left) / paintRect.width) *
      metrics.viewBoxWidth;
  final svgY =
      ((unscaledPosition.dy - paintRect.top) / paintRect.height) *
      metrics.viewBoxHeight;
  final y = (svgY / metrics.viewBoxHeight).clamp(0.0, 1.0);

  if (svgX <= metrics.bodyWidth) {
    return _hitFrontLayer(svgX / metrics.bodyWidth, y);
  }
  if (svgX >= metrics.backStart) {
    return _hitBackLayer((svgX - metrics.backStart) / metrics.bodyWidth, y);
  }
  return null;
}

Rect _svgPaintRect(Size boxSize, _BodySvgMetrics metrics) {
  final scale = math.min(
    boxSize.width / metrics.viewBoxWidth,
    boxSize.height / metrics.viewBoxHeight,
  );
  final width = metrics.viewBoxWidth * scale;
  final height = metrics.viewBoxHeight * scale;
  return Rect.fromLTWH(
    (boxSize.width - width) / 2,
    (boxSize.height - height) / 2,
    width,
    height,
  );
}

String? _hitFrontLayer(double x, double y) {
  if (_inside(y, .40, .70) && _outerLimb(x)) return 'forearms';
  if (_inside(y, .21, .48) && _outerUpperLimb(x)) return 'arms';
  if (_inside(y, .13, .25) && _wideShoulder(x)) return 'shoulders';
  if (_inside(y, .16, .30) && _inside(x, .34, .66)) return 'chest';
  if (_inside(y, .27, .55) && (_inside(x, .24, .38) || _inside(x, .62, .76))) {
    return 'obliques';
  }
  if (_inside(y, .29, .51) && _inside(x, .38, .62)) return 'abs';
  if (_inside(y, .50, .75) && _inside(x, .26, .74)) return 'quads';
  if (_inside(y, .74, .98) && _inside(x, .28, .72)) return 'calves';
  return null;
}

String? _hitBackLayer(double x, double y) {
  if (_inside(y, .42, .69) && _outerLimb(x)) return 'forearms';
  if (_inside(y, .24, .49) && _outerUpperLimb(x)) return 'arms';
  if (_inside(y, .13, .25) && _wideShoulder(x)) return 'shoulders';
  if (_inside(y, .08, .23) && _inside(x, .35, .65)) return 'traps';
  if (_inside(y, .19, .50) && _inside(x, .25, .75)) return 'lats';
  if (_inside(y, .48, .61) && _inside(x, .31, .69)) return 'glutes';
  if (_inside(y, .59, .78) && _inside(x, .29, .71)) return 'hamstrings';
  if (_inside(y, .76, .98) && _inside(x, .29, .71)) return 'calves';
  return null;
}

bool _inside(double value, double min, double max) =>
    value >= min && value <= max;

bool _outerLimb(double x) => x <= .23 || x >= .77;

bool _outerUpperLimb(double x) => x <= .27 || x >= .73;

bool _wideShoulder(double x) => x <= .36 || x >= .64;

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
  if (normalized.contains('chest')) return const Color(0xFFD9362F);
  if (normalized.contains('back')) return const Color(0xFF007C70);
  if (normalized.contains('shoulder')) return const Color(0xFFD29600);
  if (normalized.contains('arm') ||
      normalized.contains('bicep') ||
      normalized.contains('tricep')) {
    return const Color(0xFF6630BF);
  }
  if (normalized.contains('core') || normalized.contains('ab')) {
    return const Color(0xFF439E2E);
  }
  if (normalized.contains('hamstring')) return const Color(0xFFE6432A);
  if (normalized.contains('glute')) return const Color(0xFFD92E73);
  if (normalized.contains('calf')) return const Color(0xFF007E68);
  if (normalized.contains('leg') || normalized.contains('quad')) {
    return const Color(0xFF1268D8);
  }
  if (normalized.contains('cardio')) return const Color(0xFFD76E00);
  return AppColors.gold;
}

Color _bodyLayerColor(String assetName) {
  return switch (assetName) {
    'chest' => _muscleColor('Chest'),
    'shoulders' => _muscleColor('Shoulders'),
    'arms' => _muscleColor('Arms'),
    'forearms' => const Color(0xFF4C39B6),
    'abs' => _muscleColor('Core'),
    'obliques' => const Color(0xFF4E9E35),
    'lats' => _muscleColor('Back'),
    'traps' => const Color(0xFF007FA3),
    'quads' => _muscleColor('Legs'),
    'hamstrings' => _muscleColor('Hamstrings'),
    'glutes' => _muscleColor('Glutes'),
    'calves' => _muscleColor('Calves'),
    _ => AppColors.gold,
  };
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
