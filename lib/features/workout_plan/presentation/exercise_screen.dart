import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:deepfitness/features/workout_plan/presentation/skip_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The exercise the member is on: tick off sets, then complete or skip.
///
/// It always shows the plan's current exercise rather than an index
/// passed in, so a plan advanced on another device cannot leave this
/// screen logging against the wrong one.
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _setsDone = 0;

  Future<void> _finish(
    AssignedPlan plan,
    PlanExercise exercise, {
    required bool skipped,
  }) async {
    String? reason;
    if (skipped) {
      // A skip is refused without a reason, and still advances the plan,
      // so a member is never stuck on an exercise they cannot do today.
      reason = await showSkipReasonSheet(context);
      if (reason == null || !mounted) return;
    }

    final controller = ref.read(planProgressControllerProvider.notifier);
    final ok = skipped
        ? await controller.skip(
            plan: plan,
            exercise: exercise,
            reason: reason!,
          )
        : await controller.complete(
            plan: plan,
            exercise: exercise,
            setsDone: _setsDone,
          );

    if (!mounted) return;
    if (ok) {
      setState(() => _setsDone = 0);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(currentPlanProvider).value;
    final exercise = plan?.currentExercise;
    final busy = ref.watch(planProgressControllerProvider).isLoading;
    final theme = Theme.of(context).textTheme;

    if (plan == null || exercise == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(),
        body: const DfMessage(
          icon: Icons.check_circle_outline,
          title: 'Nothing to do',
          body: 'Every exercise in this plan is behind you.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('EXERCISE ${plan.currentIndex + 1}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Insets.margin),
            child: Center(
              child: DfLabel(
                '${plan.exercises.length - plan.currentIndex} remaining',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.margin,
            Insets.md,
            Insets.margin,
            Insets.xl,
          ),
          children: [
            if (exercise.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.base),
                child: Image.network(
                  exercise.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: Insets.md),
            Text(exercise.name.toUpperCase(), style: theme.headlineLarge),
            const SizedBox(height: Insets.xs),
            Row(
              children: [
                const Icon(
                  Icons.track_changes,
                  size: 14,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: Insets.xs),
                DfLabel(
                  '${exercise.sets} sets × ${exercise.reps} reps',
                  colour: AppColors.onSurfaceVariant,
                ),
                if (exercise.muscleGroup.isNotEmpty) ...[
                  const SizedBox(width: Insets.sm),
                  DfLabel('• ${exercise.muscleGroup}'),
                ],
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: Insets.md),
              Text(
                exercise.description,
                style: theme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Insets.lg),
            DfCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: DfLabel('Sets logged')),
                      DfLabel(
                        '$_setsDone of ${exercise.sets}',
                        colour: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  _SetGrid(
                    total: exercise.sets,
                    reps: exercise.reps,
                    done: _setsDone,
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _setsDone = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),
            DfPrimaryButton(
              label: 'Mark complete',
              trailingIcon: Icons.check,
              busy: busy,
              onPressed: () => _finish(plan, exercise, skipped: false),
            ),
            const SizedBox(height: Insets.sm),
            DfSecondaryButton(
              label: 'Skip this exercise',
              icon: Icons.skip_next,
              onPressed: busy
                  ? null
                  : () => _finish(plan, exercise, skipped: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tile per set, showing the target, filling as they are logged.
class _SetGrid extends StatelessWidget {
  const _SetGrid({
    required this.total,
    required this.reps,
    required this.done,
    this.onChanged,
  });

  final int total;
  final int reps;
  final int done;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: List.generate(total, (index) {
        final filled = index < done;
        return GestureDetector(
          // Tapping the last filled tile undoes it, so a mis-tap does
          // not need the screen to be left and come back.
          onTap: onChanged == null
              ? null
              : () => onChanged!(filled && index == done - 1 ? index : index + 1),
          child: Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: Insets.sm),
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Column(
              children: [
                DfLabel(
                  'Set ${index + 1}',
                  colour: filled
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  '× $reps',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: filled
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
