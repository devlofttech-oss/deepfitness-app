import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every plan the member has been given, newest first.
///
/// A plan is never deleted when a new one is assigned, so this is where
/// the older ones stay readable.
class PlanHistoryScreen extends ConsumerWidget {
  const PlanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(planHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(title: const Text('Past plans')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Could not load your plans. Check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText(context)),
              ),
            ),
          ),
          data: (plans) => plans.isEmpty
              ? Center(
                  child: Text(
                    'No plans yet.',
                    style: TextStyle(color: AppColors.secondaryText(context)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _HistoryCard(
                    plan: plans[index],
                    isCurrent: index == 0,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.plan, required this.isCurrent});

  final AssignedPlan plan;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final assigned = plan.assignedAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        // The newest assignment is the one the home screen shows, so it
        // is marked rather than left to be guessed from the order.
        border: isCurrent
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.6))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isCurrent)
                const Text('Current', style: TextStyle(color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (assigned != null)
                'Assigned ${assigned.day}/${assigned.month}/${assigned.year}',
              '${plan.currentIndex} of ${plan.exercises.length} done',
              if (plan.isComplete) 'Complete',
            ].join(' · '),
            style: TextStyle(
              color: plan.isComplete
                  ? AppColors.success
                  : AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 6,
              backgroundColor: AppColors.canvas(context),
            ),
          ),
        ],
      ),
    );
  }
}
