import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/metric_cell.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:deepfitness/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider);

    return PremiumScaffold(
      bottomPadding: 128,
      child: AsyncStateView(
        value: workout,
        errorTitle: 'Could not load workout details',
        onRetry: () => ref.invalidate(workoutProvider),
        data: (workoutData) => _WorkoutDetailContent(workout: workoutData),
      ),
    );
  }
}

class _WorkoutDetailContent extends ConsumerWidget {
  const _WorkoutDetailContent({required this.workout});

  final WorkoutPlan workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(title: 'Workout Details', onBack: () => context.pop()),
        const SizedBox(height: 26),
        Row(
          children: [
            const IconTile(icon: Icons.fitness_center_rounded, size: 58),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Build Strength  •  ${workout.focus}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        PremiumCard(
          child: Row(
            children: [
              MetricCell(
                icon: Icons.schedule_rounded,
                value: '${workout.durationMinutes} min',
                label: 'Duration',
              ),
              const _Divider(),
              MetricCell(
                icon: Icons.fitness_center_rounded,
                value: '${workout.exercises.length}',
                label: 'Exercises',
              ),
              const _Divider(),
              MetricCell(
                icon: Icons.local_fire_department_outlined,
                value: '${workout.estimatedCalories} kcal',
                label: 'Est. Calories',
              ),
              const _Divider(),
              MetricCell(
                icon: Icons.trending_up_rounded,
                value: workout.level,
                label: 'Level',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PremiumCard(
          color: AppColors.goldSoft,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.goldBright,
                child: Icon(Icons.info_outline_rounded, color: AppColors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Focus on controlled movements and proper form.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SectionTitle(
          title: 'Exercises',
          action: TextButton.icon(
            onPressed: () => _showExerciseSummary(context, workout.exercises),
            icon: const Icon(Icons.list_rounded, color: AppColors.gold),
            label: const Text(
              'View as List',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: [
              if (workout.exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _InlineEmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No exercises assigned',
                    message: 'Ask your trainer to assign a workout plan.',
                  ),
                ),
              for (var index = 0; index < workout.exercises.length; index++)
                _ExerciseRow(
                  index: index + 1,
                  exercise: workout.exercises[index],
                  showDivider: index != workout.exercises.length - 1,
                  onTap: () {
                    ref
                        .read(selectedExerciseProvider.notifier)
                        .select(workout.exercises[index]);
                    context.push('/exercise-log');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Start Workout',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            if (workout.exercises.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No workout assigned yet.')),
              );
              return;
            }
            ref
                .read(selectedExerciseProvider.notifier)
                .select(workout.exercises.first);
            context.push('/exercise-log');
          },
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareButton(icon: Icons.chevron_left_rounded, onTap: onBack),
        const SizedBox(width: 22),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SquareButton(
          icon: Icons.more_horiz_rounded,
          onTap: () => _showWorkoutOptions(context),
        ),
      ],
    );
  }
}

void _showExerciseSummary(BuildContext context, List<Exercise> exercises) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Exercise List',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final exercise in exercises)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(exercise.name),
            subtitle: Text('${exercise.sets} sets - ${exercise.reps} reps'),
          ),
      ],
    ),
  );
}

void _showWorkoutOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: const Text('Restart workout'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout progress reset.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share workout'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout summary copied.')),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.exercise,
    required this.showDivider,
    required this.onTap,
  });

  final int index;
  final Exercise exercise;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.goldSoft,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 64,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.secondaryText(context),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.sets} Sets  •  ${exercise.reps} Reps',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                      Text(
                        'Rest ${exercise.restSeconds} sec',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 22),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 58, color: AppColors.divider(context));
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
