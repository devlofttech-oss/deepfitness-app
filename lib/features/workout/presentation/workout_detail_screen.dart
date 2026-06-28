import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:deepfitness/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        _TopBar(
          title: 'Workout Details',
          onBack: () => context.pop(),
          onMore: () => _showWorkoutOptions(context, ref, workout),
        ),
        const SizedBox(height: 22),
        PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile(icon: Icons.fitness_center_rounded, size: 50),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          workout.focus,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.secondaryText(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  _WorkoutStatTile(
                    icon: Icons.schedule_rounded,
                    value: '${workout.durationMinutes} min',
                    label: 'Duration',
                  ),
                  _WorkoutStatTile(
                    icon: Icons.fitness_center_rounded,
                    value: '${workout.exercises.length}',
                    label: 'Exercises',
                  ),
                  _WorkoutStatTile(
                    icon: Icons.local_fire_department_outlined,
                    value: '${workout.estimatedCalories} kcal',
                    label: 'Calories',
                  ),
                  _WorkoutStatTile(
                    icon: Icons.trending_up_rounded,
                    value: workout.level,
                    label: 'Level',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PremiumCard(
          color: AppColors.chipBackground(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 17,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onMore,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onMore;

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
        _SquareButton(icon: Icons.more_horiz_rounded, onTap: onMore),
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

void _showWorkoutOptions(
  BuildContext context,
  WidgetRef ref,
  WorkoutPlan workout,
) {
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
            onTap: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(appDataRepositoryProvider)
                    .resetWorkoutProgress(workout);
                ref.invalidate(exerciseLogsProvider);
                ref.invalidate(progressProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout progress reset.')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(friendlyErrorMessage(error))),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share workout'),
            onTap: () async {
              Navigator.pop(context);
              final summary = ref
                  .read(appDataRepositoryProvider)
                  .workoutShareText(workout);
              await Clipboard.setData(ClipboardData(text: summary));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout summary copied.')),
                );
              }
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
                  width: 66,
                  height: 50,
                  child: _ExerciseThumb(exercise: exercise),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                      Text(
                        'Rest ${exercise.restSeconds} sec',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondaryText(context),
                        ),
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

class _WorkoutStatTile extends StatelessWidget {
  const _WorkoutStatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise.imageUrls.isEmpty
        ? null
        : exercise.imageUrls.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.subtle(context)),
        child: imageUrl == null
            ? Icon(
                Icons.fitness_center_rounded,
                color: AppColors.secondaryText(context),
                size: 24,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.secondaryText(context),
                  size: 24,
                ),
              ),
      ),
    );
  }
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
