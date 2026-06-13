import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExerciseLoggingScreen extends ConsumerWidget {
  const ExerciseLoggingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider);
    final selectedExercise = ref.watch(selectedExerciseProvider);

    return PremiumScaffold(
      child: workout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PremiumCard(child: Text(error.toString())),
        data: (workoutData) {
          if (workoutData.exercises.isEmpty) {
            return const PremiumCard(child: Text('No exercises assigned yet.'));
          }
          final exercise = selectedExercise ?? workoutData.exercises.first;
          final logs = ref.watch(exerciseLogsProvider);
          return _ExerciseLoggingContent(
            workout: workoutData,
            exercise: exercise,
            logs: logs,
          );
        },
      ),
    );
  }
}

class _ExerciseLoggingContent extends ConsumerWidget {
  const _ExerciseLoggingContent({
    required this.workout,
    required this.exercise,
    required this.logs,
  });

  final WorkoutPlan workout;
  final Exercise exercise;
  final AsyncValue<List<ExerciseLog>> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SquareButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${workout.exercises.indexWhere((item) => item.id == exercise.id) + 1} of ${workout.exercises.length} Exercises',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            _SquareButton(
              icon: Icons.more_horiz_rounded,
              onTap: () => _showExerciseMenu(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        PremiumCard(
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.grey.shade700,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      exercise.description,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _Prescription(
                            icon: Icons.track_changes_rounded,
                            label: exercise.isAssigned ? 'Target' : 'Free Log',
                            value: exercise.isAssigned
                                ? '${exercise.sets} Sets  •  ${exercise.reps} Reps'
                                : 'Optional exercise',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 54,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _Prescription(
                            icon: Icons.schedule_rounded,
                            label: 'Rest',
                            value: '${exercise.restSeconds} sec',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Log Your Sets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showHelp(context),
              icon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.gold,
              ),
              label: const Text(
                'Need Help?',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        logs.when(
          loading: () => const PremiumCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => PremiumCard(child: Text(error.toString())),
          data: (items) => PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++)
                  _SetLogRow(
                    log: items[index],
                    assignedSetCount: exercise.sets,
                    showDivider: index != items.length - 1,
                    onChanged: (updated) {
                      ref
                          .read(exerciseLogsProvider.notifier)
                          .updateAt(index, updated);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Add Extra Sets (Optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: InkWell(
            onTap: () => ref.read(exerciseLogsProvider.notifier).addExtraSet(),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.background,
                  child: Icon(Icons.add_rounded, color: AppColors.muted),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Extra Set',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Tap to log',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save Sets',
          icon: Icons.save_outlined,
          onPressed: () async {
            await ref.read(exerciseLogsProvider.notifier).save(exercise);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sets saved to Supabase.')),
              );
            }
          },
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Complete Exercise',
          icon: Icons.sports_score_rounded,
          outline: true,
          onPressed: () {
            final currentIndex = workout.exercises.indexWhere(
              (item) => item.id == exercise.id,
            );
            if (currentIndex >= 0 &&
                currentIndex < workout.exercises.length - 1) {
              ref
                  .read(selectedExerciseProvider.notifier)
                  .select(workout.exercises[currentIndex + 1]);
              ref.invalidate(exerciseLogsProvider);
            } else {
              context.pop();
            }
          },
        ),
      ],
    );
  }
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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

class _Prescription extends StatelessWidget {
  const _Prescription({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _SetLogRow extends StatelessWidget {
  const _SetLogRow({
    required this.log,
    required this.assignedSetCount,
    required this.showDivider,
    required this.onChanged,
  });

  final ExerciseLog log;
  final int assignedSetCount;
  final bool showDivider;
  final ValueChanged<ExerciseLog> onChanged;

  @override
  Widget build(BuildContext context) {
    final isMandatory = log.setNumber <= assignedSetCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: AppColors.goldBright,
                    child: Text(
                      '${log.setNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    'Set ${log.setNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _Chip(isMandatory ? 'Trainer Prescribed' : 'Extra'),
                  const Spacer(),
                  _Chip(isMandatory ? 'Mandatory' : 'Optional'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StepperField(
                      label: 'Weight (kg)',
                      value: log.weight,
                      onMinus: () => onChanged(
                        ExerciseLog(
                          id: log.id,
                          setNumber: log.setNumber,
                          weight: (log.weight - 5).clamp(0, 500),
                          reps: log.reps,
                          completed: log.completed,
                        ),
                      ),
                      onPlus: () => onChanged(
                        ExerciseLog(
                          id: log.id,
                          setNumber: log.setNumber,
                          weight: log.weight + 5,
                          reps: log.reps,
                          completed: log.completed,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _StepperField(
                      label: 'Reps',
                      value: log.reps,
                      onMinus: () => onChanged(
                        ExerciseLog(
                          id: log.id,
                          setNumber: log.setNumber,
                          weight: log.weight,
                          reps: (log.reps - 1).clamp(0, 100),
                          completed: log.completed,
                        ),
                      ),
                      onPlus: () => onChanged(
                        ExerciseLog(
                          id: log.id,
                          setNumber: log.setNumber,
                          weight: log.weight,
                          reps: log.reps + 1,
                          completed: log.completed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => onChanged(
                      ExerciseLog(
                        id: log.id,
                        setNumber: log.setNumber,
                        weight: log.weight,
                        reps: log.reps,
                        completed: !log.completed,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 58,
                      height: 46,
                      decoration: BoxDecoration(
                        color: log.completed
                            ? AppColors.goldBright
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        log.completed
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _RoundIcon(icon: Icons.remove_rounded, onTap: onMinus),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RoundIcon(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.black,
      ),
      icon: Icon(icon),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFC37E00),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void _showExerciseMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Start rest timer'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rest timer started.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Add note'),
            onTap: () {
              Navigator.pop(context);
              _showNoteDialog(context);
            },
          ),
        ],
      ),
    ),
  );
}

void _showHelp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logging Help'),
      content: const Text(
        'Adjust weight and reps for each set. Tap the check button to mark a set complete. Trainer targets stay visible for reference.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

Future<void> _showNoteDialog(BuildContext context) async {
  final note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exercise Note'),
      content: TextField(
        controller: note,
        decoration: const InputDecoration(hintText: 'How did it feel?'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note saved locally.')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  note.dispose();
}
