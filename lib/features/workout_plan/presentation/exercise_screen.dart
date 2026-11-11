import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:deepfitness/features/workout_plan/presentation/skip_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The exercise the member is on: tick off sets, then complete or skip.
///
/// It always shows the plan's current exercise rather than an index passed
/// in, so a plan advanced on another device cannot leave this screen
/// logging against the wrong one.
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _setsDone = 0;

  Future<void> _complete(AssignedPlan plan, PlanExercise exercise) async {
    final ok = await ref
        .read(planProgressControllerProvider.notifier)
        .complete(plan: plan, exercise: exercise, setsDone: _setsDone);

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

  Future<void> _skip(AssignedPlan plan, PlanExercise exercise) async {
    // A skip is refused without a reason, and still advances the plan, so
    // a member is never stuck on an exercise they cannot do today.
    final reason = await showSkipReasonSheet(context);
    if (reason == null || !mounted) return;

    final ok = await ref
        .read(planProgressControllerProvider.notifier)
        .skip(plan: plan, exercise: exercise, reason: reason);

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

    if (plan == null || exercise == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(),
        body: const Center(child: Text('Nothing to do right now.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(title: Text(exercise.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (exercise.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    exercise.photoUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                '${exercise.sets} sets of ${exercise.reps}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (exercise.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  exercise.description,
                  style: TextStyle(color: AppColors.secondaryText(context)),
                ),
              ],
              const SizedBox(height: 24),
              _SetCounter(
                total: exercise.sets,
                done: _setsDone,
                onChanged: busy
                    ? null
                    : (value) => setState(() => _setsDone = value),
              ),
              const SizedBox(height: 32),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else ...[
                PrimaryButton(
                  label: 'Mark complete',
                  onPressed: () => _complete(plan, exercise),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Skip this exercise',
                  outline: true,
                  onPressed: () => _skip(plan, exercise),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable dots, one per set.
class _SetCounter extends StatelessWidget {
  const _SetCounter({
    required this.total,
    required this.done,
    this.onChanged,
  });

  final int total;
  final int done;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sets done', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: List.generate(total, (index) {
            final filled = index < done;
            return GestureDetector(
              // Tapping the dot that is already the last filled one undoes
              // it, so a mis-tap does not need the screen to be left.
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(filled && index == done - 1
                        ? index
                        : index + 1),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: filled
                    ? AppColors.gold
                    : AppColors.surface(context),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: filled ? AppColors.black : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
