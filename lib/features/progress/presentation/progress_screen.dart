import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return PremiumScaffold(
      bottomPadding: 132,
      child: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PremiumCard(child: Text(error.toString())),
        data: (progress) => _ProgressContent(progress: progress),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.progress});

  final MemberProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Progress',
          subtitle: 'Your journey so far.',
          action: IconButton(
            onPressed: () => showDateRangePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              initialDateRange: DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
            ),
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
                      'Current Weight',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.muted,
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
                                fontSize: 38,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 8),
                          child: Text(
                            'kg',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '+${progress.weightDelta.toStringAsFixed(1)} kg  this month',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      'Workouts Completed',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${progress.workoutsThisMonth}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                      ),
                    ),
                    Text(
                      'this month',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              ProgressRing(value: progress.goalCompletion, size: 86),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ThreeMetricCard(
          title: 'Muscle Progress',
          items: progress.muscleProgress.entries
              .map(
                (entry) => _ProgressItem(
                  icon: _muscleIcon(entry.key),
                  label: entry.key,
                  value: '+${entry.value}%',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _ThreeMetricCard(
          title: 'Personal Bests',
          items: progress.personalBests.entries
              .map(
                (entry) => _ProgressItem(
                  icon: _bestIcon(entry.key),
                  label: entry.key,
                  value: '${entry.value} kg',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  IconData _muscleIcon(String key) {
    return switch (key) {
      'Back' => Icons.accessibility_new_rounded,
      'Legs' => Icons.directions_walk_rounded,
      _ => Icons.self_improvement_rounded,
    };
  }

  IconData _bestIcon(String key) {
    return switch (key) {
      'Squat' => Icons.accessibility_new_rounded,
      'Deadlift' => Icons.fitness_center_rounded,
      _ => Icons.horizontal_rule_rounded,
    };
  }
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

class _ThreeMetricCard extends StatelessWidget {
  const _ThreeMetricCard({required this.title, required this.items});

  final String title;
  final List<_ProgressItem> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _Metric(item: items[index])),
                if (index != items.length - 1)
                  Container(width: 1, height: 72, color: AppColors.border),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.item});

  final _ProgressItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(item.icon, color: AppColors.gold, size: 26),
        const SizedBox(height: 8),
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
