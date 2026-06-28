import 'dart:async';

import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
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
      child: AsyncStateView(
        value: workout,
        errorTitle: 'Could not load exercise logging',
        onRetry: () => ref.invalidate(workoutProvider),
        data: (workoutData) {
          if (workoutData.exercises.isEmpty) {
            return const AppEmptyState(
              title: 'No exercises assigned',
              message:
                  'Ask your trainer to assign a workout before logging sets.',
              icon: Icons.fitness_center_rounded,
            );
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
              onTap: () => _goBackOr(context, '/workout'),
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
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${workout.exercises.indexWhere((item) => item.id == exercise.id) + 1} of ${workout.exercises.length} Exercises',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _SquareButton(
              icon: Icons.more_horiz_rounded,
              onTap: () => _showExerciseMenu(context, ref, exercise),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AspectRatio(
          aspectRatio: 1.55,
          child: _ExerciseMotionPreview(exercise: exercise, borderRadius: 20),
        ),
        const SizedBox(height: 16),
        Text(
          exercise.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: _Prescription(
                  icon: Icons.track_changes_rounded,
                  label: exercise.isAssigned ? 'Target' : 'Free Log',
                  value: exercise.isAssigned
                      ? '${exercise.sets} Sets'
                      : 'Optional exercise',
                ),
              ),
              Container(
                width: 1,
                height: 54,
                color: AppColors.divider(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _Prescription(
                    icon: Icons.schedule_rounded,
                    label: 'Rest',
                    value: '${exercise.restSeconds} sec',
                  ),
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
        AsyncStateView(
          value: logs,
          errorTitle: 'Could not load your sets',
          loading: const AppLoadingState(rows: 2),
          onRetry: () => ref.invalidate(exerciseLogsProvider),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryText(context),
                  fontSize: 13,
                ),
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.subtle(context),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.secondaryText(context),
                    size: 20,
                  ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText(context),
                    fontSize: 13,
                  ),
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
            try {
              await ref.read(exerciseLogsProvider.notifier).save(exercise);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sets saved to Supabase.')),
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
              _goBackOr(context, '/workout');
            }
          },
        ),
      ],
    );
  }
}

class _ExerciseMotionPreview extends StatefulWidget {
  const _ExerciseMotionPreview({
    required this.exercise,
    this.borderRadius = 18,
  });

  final Exercise exercise;
  final double borderRadius;

  @override
  State<_ExerciseMotionPreview> createState() => _ExerciseMotionPreviewState();
}

class _ExerciseMotionPreviewState extends State<_ExerciseMotionPreview> {
  Timer? _timer;
  int _index = 0;

  List<String> get _images => widget.exercise.imageUrls;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ExerciseMotionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.imageUrls != widget.exercise.imageUrls) {
      _index = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_images.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _images.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final dotCount = images.length > 2 ? 2 : images.length;
    final activeDot = dotCount == 0 ? 0 : _index % dotCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.subtle(context)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              const _ExerciseImageFallback()
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Image.network(
                  images[_index % images.length],
                  key: ValueKey('${widget.exercise.id}-$_index'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ExerciseImageFallback(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const _ExerciseImageFallback();
                  },
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  for (var i = 0; i < dotCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: i == activeDot ? 14 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i == activeDot
                            ? AppColors.goldBright
                            : AppColors.white.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(99),
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

class _ExerciseImageFallback extends StatelessWidget {
  const _ExerciseImageFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.secondaryText(context),
        size: 30,
      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
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
                    radius: 18,
                    backgroundColor: AppColors.goldBright,
                    child: Text(
                      '${log.setNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Set ${log.setNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(isMandatory ? 'Trainer' : 'Extra'),
                        _Chip(isMandatory ? 'Mandatory' : 'Optional'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: isMandatory
                        ? _ReadonlyMetricField(
                            label: 'Weight (kg)',
                            value: log.weight,
                          )
                        : _StepperField(
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
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.divider(context),
                  ),
                  Expanded(
                    child: isMandatory
                        ? _ReadonlyMetricField(label: 'Reps', value: log.reps)
                        : _StepperField(
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
                  const SizedBox(width: 10),
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
                      width: 48,
                      height: 42,
                      decoration: BoxDecoration(
                        color: log.completed
                            ? AppColors.goldBright
                            : AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        log.completed
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 20,
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.secondaryText(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider(context)),
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
                    fontSize: 17,
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

class _ReadonlyMetricField extends StatelessWidget {
  const _ReadonlyMetricField({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.secondaryText(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider(context)),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
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
        backgroundColor: AppColors.subtle(context),
        foregroundColor: AppColors.text(context),
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.isDark(context)
              ? AppColors.goldBright
              : const Color(0xFFC37E00),
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

void _showExerciseMenu(BuildContext context, WidgetRef ref, Exercise exercise) {
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
              _showRestTimer(context, exercise.restSeconds);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Add note'),
            onTap: () {
              Navigator.pop(context);
              _showNoteDialog(context, ref, exercise);
            },
          ),
        ],
      ),
    ),
  );
}

void _showRestTimer(BuildContext context, int totalSeconds) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _RestTimerSheet(totalSeconds: totalSeconds),
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

Future<void> _showNoteDialog(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise,
) async {
  final note = TextEditingController(
    text: await ref.read(appDataRepositoryProvider).fetchExerciseNote(exercise),
  );
  if (!context.mounted) {
    note.dispose();
    return;
  }
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
          onPressed: () async {
            try {
              await ref
                  .read(appDataRepositoryProvider)
                  .saveExerciseNote(exercise, note.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Note saved.')));
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(friendlyErrorMessage(error))),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  note.dispose();
}

class _RestTimerSheet extends StatefulWidget {
  const _RestTimerSheet({required this.totalSeconds});

  final int totalSeconds;

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds.clamp(1, 900);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final progress = _secondsLeft / widget.totalSeconds.clamp(1, 900);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _secondsLeft == 0 ? 'Rest complete' : 'Rest Timer',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  color: AppColors.gold,
                  backgroundColor: AppColors.divider(context),
                ),
                Center(
                  child: Text(
                    '$minutes:$seconds',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_secondsLeft == 0 ? 'Done' : 'Stop Timer'),
          ),
        ],
      ),
    );
  }
}

void _goBackOr(BuildContext context, String fallbackRoute) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}
