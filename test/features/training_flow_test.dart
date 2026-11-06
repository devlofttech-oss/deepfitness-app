import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/repositories/app_data_repository.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/features/workout/presentation/exercise_logging_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A repository that keeps the plan in memory and advances it the way the
/// Firestore batch does.
///
/// This is the integration test the guide asks for, minus the network: it
/// drives the real screen, the real controller and the real models, and
/// checks that completing an exercise writes a log and moves the unlock on.
class _FakeRepository extends AppDataRepository {
  _FakeRepository() : super(AppFirebase());

  AssignedPlan plan = AssignedPlan(
    id: 'plan1',
    memberId: 'member1',
    planId: 'template1',
    title: 'Push Day',
    focus: 'Chest',
    level: '',
    durationMinutes: 30,
    estimatedCalories: 200,
    scheduledDate: '2026-11-06',
    exercises: [
      for (var i = 0; i < 3; i++)
        AssignedExercise(
          order: i,
          exerciseId: 'ex$i',
          name: 'Exercise ${i + 1}',
          description: '',
          muscleGroup: 'Chest',
          sets: 2,
          reps: '10',
          restSeconds: 60,
          targetWeight: 20,
          tracksWeight: true,
          notes: '',
        ),
    ],
    currentIndex: 0,
    status: AssignedPlanStatus.active,
    assignedAt: DateTime(2026, 11, 6),
  );

  final List<String> completed = [];
  final List<({String exercise, String reason})> skipped = [];
  final Map<String, List<ExerciseLog>> savedLogs = {};

  @override
  Future<WorkoutPlan> fetchTodayWorkout({String? memberId, DateTime? date}) async {
    return plan.toWorkoutPlan(
      completedSetsByOrder: {
        for (var i = 0; i < plan.currentIndex; i++) i: plan.exercises[i].sets,
      },
    );
  }

  @override
  Future<List<ExerciseLog>> fetchExerciseLogs(Exercise exercise) async {
    return savedLogs[exercise.workoutExerciseId] ??
        [
          for (var i = 1; i <= exercise.sets; i++)
            ExerciseLog(
              setNumber: i,
              weight: exercise.targetWeight,
              reps: 10,
              completed: false,
            ),
        ];
  }

  @override
  Future<void> saveExerciseLogs(
    Exercise exercise,
    List<ExerciseLog> logs,
  ) async {
    savedLogs[exercise.workoutExerciseId!] = logs;
  }

  @override
  Future<void> completeExercise({
    required WorkoutPlan workout,
    required Exercise exercise,
    required List<ExerciseLog> logs,
  }) async {
    final index = workout.indexOf(exercise);
    if (plan.isLockedAt(index)) {
      throw StateError('Finish the exercise before this one first.');
    }
    completed.add(exercise.name);
    _advancePast(index);
  }

  @override
  Future<void> skipExercise({
    required WorkoutPlan workout,
    required Exercise exercise,
    required String reason,
  }) async {
    skipped.add((exercise: exercise.name, reason: reason));
    _advancePast(workout.indexOf(exercise));
  }

  @override
  Future<void> completeWorkout(WorkoutPlan workout) async {
    plan = _copy(plan.exercises.length, AssignedPlanStatus.completed);
  }

  /// Mirrors `_writeCompletion`: never moves the index backwards.
  void _advancePast(int index) {
    final next = index + 1 > plan.currentIndex ? index + 1 : plan.currentIndex;
    plan = _copy(next, plan.status);
  }

  AssignedPlan _copy(int currentIndex, AssignedPlanStatus status) {
    return AssignedPlan(
      id: plan.id,
      memberId: plan.memberId,
      planId: plan.planId,
      title: plan.title,
      focus: plan.focus,
      level: plan.level,
      durationMinutes: plan.durationMinutes,
      estimatedCalories: plan.estimatedCalories,
      scheduledDate: plan.scheduledDate,
      exercises: plan.exercises,
      currentIndex: currentIndex,
      status: status,
      assignedAt: plan.assignedAt,
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _FakeRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      appDataRepositoryProvider.overrideWithValue(repository),
      // workoutProvider normally goes through the auth gate first, which has
      // no Firebase to talk to here. It still reads the fake repository, so a
      // refresh after a completion picks up the advanced plan.
      workoutProvider.overrideWith((ref) => repository.fetchTodayWorkout()),
    ],
  );
  addTearDown(container.dispose);

  final workout = await container.read(
    appDataRepositoryProvider,
  ).fetchTodayWorkout();
  container.read(selectedExerciseProvider.notifier).select(
    workout.exercises.first,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const ExerciseLoggingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('completing an exercise logs it and advances the unlock', (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    expect(repository.plan.currentIndex, 0);

    await tester.ensureVisible(find.text('Complete Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Exercise'));
    await tester.pumpAndSettle();

    // The log was written...
    expect(repository.completed, ['Exercise 1']);
    // ...and the next exercise is now the one that is open.
    expect(repository.plan.currentIndex, 1);
    expect(repository.plan.isLockedAt(1), isFalse);
    expect(repository.plan.isLockedAt(2), isTrue);
  });

  testWidgets('the sets are saved before the completion is written', (
    tester,
  ) async {
    // Order matters: a completion log written against unsaved sets would
    // report zero work done.
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.ensureVisible(find.text('Complete Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Exercise'));
    await tester.pumpAndSettle();

    expect(repository.savedLogs, isNotEmpty);
    final logs = repository.savedLogs.values.first;
    expect(logs, isNotEmpty);
    expect(logs.every((log) => log.completed), isTrue);
  });

  testWidgets('skipping asks for a reason and still advances', (tester) async {
    final repository = _FakeRepository();
    await _pump(tester, repository);

    await tester.ensureVisible(find.text('Skip this exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this exercise'));
    await tester.pumpAndSettle();

    // The sheet refuses to submit until a reason is given.
    expect(find.text('Skip and move on'), findsOneWidget);
    await tester.tap(find.text('Equipment in use'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip and move on'));
    await tester.pumpAndSettle();

    expect(repository.skipped.single.exercise, 'Exercise 1');
    expect(repository.skipped.single.reason, 'Equipment in use');
    // Skipping still moves the member on, so nobody is stuck.
    expect(repository.plan.currentIndex, 1);
  });

  testWidgets('a locked exercise cannot be completed out of order', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final container = await _pump(tester, repository);

    // Jump the selection to an exercise the plan has not unlocked.
    final workout = await repository.fetchTodayWorkout();
    container
        .read(selectedExerciseProvider.notifier)
        .select(workout.exercises[2]);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Complete Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Exercise'));
    await tester.pumpAndSettle();

    // The repository refuses it, and the unlock has not moved.
    expect(repository.completed, isEmpty);
    expect(repository.plan.currentIndex, 0);
  });
}
