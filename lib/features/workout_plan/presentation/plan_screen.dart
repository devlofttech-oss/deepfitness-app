import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/widgets/df_chrome.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('ALL WORKOUTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Past plans',
            onPressed: () => context.push('/plan/history'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: plan.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const DfMessage(
            icon: Icons.wifi_off,
            title: 'Could not load your plan',
            body: 'Check your connection and try again.',
          ),
          data: (data) => data == null || data.isEmpty
              ? const DfMessage(
                  icon: Icons.fitness_center,
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
      padding: const EdgeInsets.fromLTRB(
        Insets.margin,
        Insets.md,
        Insets.margin,
        Insets.xl,
      ),
      itemCount: plan.exercises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
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
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.title.toUpperCase(), style: theme.headlineLarge),
        const SizedBox(height: Insets.xs),
        DfLabel('${plan.exercises.length} exercises'),
        const SizedBox(height: Insets.md),
        DfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DfLabel('Session progress'),
                        const SizedBox(height: Insets.xs),
                        Text(
                          '${plan.currentIndex} of ${plan.exercises.length} '
                          'exercises done'.toUpperCase(),
                          style: theme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(plan.progress * 100).round()}%',
                        style: theme.headlineLarge,
                      ),
                      const DfLabel('Complete'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              DfProgressBar(value: plan.progress),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            const Expanded(child: DfLabel('Sequence order')),
            if (plan.isComplete)
              const DfLabel('Complete', colour: AppColors.primaryContainer),
          ],
        ),
        const SizedBox(height: Insets.sm),
      ],
    );
  }
}

/// How an exercise in the list reads: still to come, the one to do now,
/// or finished one way or the other.
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
    final theme = Theme.of(context).textTheme;
    final locked = state == _TileState.locked;
    final active = state == _TileState.active;

    return DfCard(
      onTap: onTap,
      // The one that is up next carries the accent bar and sits on a
      // lighter surface; everything else recedes.
      leadingAccent: active,
      colour: active
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StateIcon(state: state, number: number),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name.toUpperCase(),
                        style: theme.headlineSmall?.copyWith(
                          // A locked exercise stays visible, so the
                          // member can see what is coming, but reads as
                          // clearly inert.
                          color: locked
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    _StateBadge(state: state),
                  ],
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  '${exercise.sets} sets × ${exercise.reps} reps',
                  style: theme.bodySmall?.copyWith(
                    color: locked
                        ? AppColors.outline
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(height: Insets.xs),
                  Text(
                    'Unlocks in sequence',
                    style: theme.bodySmall?.copyWith(color: AppColors.outline),
                  ),
                ],
                if (active) ...[
                  const SizedBox(height: Insets.md),
                  DfPrimaryButton(
                    label: 'Log this exercise',
                    trailingIcon: Icons.play_arrow,
                    onPressed: onTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The right-hand badge: done, skipped, locked, or up next.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final _TileState state;

  @override
  Widget build(BuildContext context) {
    final (text, colour) = switch (state) {
      _TileState.complete => ('Done', AppColors.onSurfaceVariant),
      _TileState.skipped => ('Skipped', AppColors.outline),
      _TileState.locked => ('Locked', AppColors.outline),
      _TileState.active => ('Up next', AppColors.primaryContainer),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state == _TileState.locked)
          const Padding(
            padding: EdgeInsets.only(right: Insets.xs),
            child: Icon(
              Icons.lock_outline,
              size: 12,
              color: AppColors.outline,
            ),
          ),
        DfLabel(text, colour: colour),
      ],
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
      _TileState.locked => (Icons.lock_outline, AppColors.outline),
      _TileState.complete => (Icons.check, AppColors.onSurfaceVariant),
      _TileState.skipped => (Icons.remove, AppColors.outline),
      _TileState.active => (null, AppColors.primaryContainer),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: state == _TileState.active
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      alignment: Alignment.center,
      child: icon == null
          ? Text(
              '$number',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            )
          : Icon(icon, size: 18, color: colour),
    );
  }
}
