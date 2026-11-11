import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:deepfitness/features/workout_plan/data/assigned_plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The logs for the plan on screen, so a finished exercise can be shown as
/// completed or skipped rather than just "done".
final planLogsProvider = StreamProvider.family<List<CompletionLog>, String>((
  ref,
  assignedPlanId,
) {
  final memberId = ref.watch(authControllerProvider).value?.member?.id;
  if (memberId == null) return Stream.value(const []);
  return ref
      .watch(assignedPlanRepositoryProvider)
      .watchLogsForPlan(memberId: memberId, assignedPlanId: assignedPlanId);
});

/// The member's assigned plan, exercise by exercise.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(
        title: const Text('Your plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past plans',
            onPressed: () => context.push('/plan/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: plan.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const _PlanMessage(
            icon: Icons.error_outline,
            title: 'Could not load your plan',
            body: 'Check your connection and try again.',
          ),
          data: (data) => data == null || data.isEmpty
              ? const _PlanMessage(
                  icon: Icons.fitness_center_outlined,
                  title: 'No plan yet',
                  body: 'Your trainer will assign one soon.',
                )
              : _PlanBody(plan: data),
        ),
      ),
    );
  }
}

class _PlanBody extends ConsumerWidget {
  const _PlanBody({required this.plan});

  final AssignedPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlanExerciseList(
      plan: plan,
      logs: ref.watch(planLogsProvider(plan.id)).value ?? const [],
      onExerciseTap: () => context.push('/plan/exercise'),
    );
  }
}

/// The plan as a list of exercises, each in one of five states: locked,
/// active, complete, skipped, or the empty plan handled by the caller.
///
/// Kept free of providers so the states can be tested directly.
class PlanExerciseList extends StatelessWidget {
  const PlanExerciseList({
    super.key,
    required this.plan,
    required this.logs,
    this.onExerciseTap,
  });

  final AssignedPlan plan;
  final List<CompletionLog> logs;
  final VoidCallback? onExerciseTap;

  @override
  Widget build(BuildContext context) {
    // Logs are written in the order exercises are finished, and the unlock
    // only moves forward, so the nth log belongs to the nth exercise.
    bool wasSkipped(int index) => index < logs.length && logs[index].skipped;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: plan.exercises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, position) {
        if (position == 0) return _PlanHeader(plan: plan);

        final index = position - 1;
        final isCurrent = index == plan.currentIndex && !plan.isComplete;

        return _ExerciseTile(
          number: position,
          exercise: plan.exercises[index],
          state: plan.isLocked(index)
              ? _TileState.locked
              : isCurrent
              ? _TileState.active
              : wasSkipped(index)
              ? _TileState.skipped
              : _TileState.complete,
          onTap: isCurrent ? onExerciseTap : null,
        );
      },
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan});

  final AssignedPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: plan.progress,
            minHeight: 8,
            backgroundColor: AppColors.surface(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          plan.isComplete
              ? 'Plan complete. Well done.'
              : '${plan.currentIndex} of ${plan.exercises.length} done',
          style: TextStyle(
            color: plan.isComplete
                ? AppColors.success
                : AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

enum _TileState { locked, active, complete, skipped }

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.number,
    required this.exercise,
    required this.state,
    this.onTap,
  });

  final int number;
  final PlanExercise exercise;
  final _TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = state == _TileState.locked;

    return Opacity(
      // A locked exercise stays visible so the member can see what is
      // coming; it is dimmed and not tappable.
      opacity: locked ? 0.45 : 1,
      child: Material(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StateIcon(state: state, number: number),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        switch (state) {
                          _TileState.skipped => 'Skipped',
                          _TileState.complete => 'Completed',
                          _TileState.locked =>
                            'Unlocks when the one before it is done',
                          _TileState.active =>
                            '${exercise.sets} sets of ${exercise.reps}',
                        },
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state == _TileState.active)
                  const Icon(Icons.chevron_right, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state, required this.number});

  final _TileState state;
  final int number;

  @override
  Widget build(BuildContext context) {
    final (icon, colour) = switch (state) {
      _TileState.locked => (Icons.lock_outline, AppColors.muted),
      _TileState.complete => (Icons.check_circle, AppColors.success),
      _TileState.skipped => (Icons.remove_circle_outline, AppColors.muted),
      _TileState.active => (null, AppColors.gold),
    };

    return CircleAvatar(
      radius: 18,
      backgroundColor: colour.withValues(alpha: 0.15),
      child: icon == null
          ? Text('$number', style: const TextStyle(color: AppColors.gold))
          : Icon(icon, size: 20, color: colour),
    );
  }
}

class _PlanMessage extends StatelessWidget {
  const _PlanMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText(context)),
            ),
          ],
        ),
      ),
    );
  }
}
