import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/features/workout/presentation/workout_detail_screen.dart';
import 'package:deepfitness/core/repositories/app_data_repository.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the plan the way the repository does, so these tests exercise the
/// real mapping from `assigned_plans` rather than a hand-made WorkoutPlan that
/// could drift from it.
WorkoutPlan _plan({
  required int currentIndex,
  int exercises = 3,
  Map<int, int> completedSets = const {},
  AssignedPlanStatus status = AssignedPlanStatus.active,
}) {
  return AssignedPlan(
    id: 'plan1',
    memberId: 'member1',
    planId: 'template1',
    title: 'Push Day',
    focus: 'Chest and triceps',
    level: 'Intermediate',
    durationMinutes: 45,
    estimatedCalories: 320,
    scheduledDate: '2026-11-06',
    exercises: [
      for (var i = 0; i < exercises; i++)
        AssignedExercise(
          order: i,
          exerciseId: 'ex$i',
          name: 'Exercise ${i + 1}',
          description: '',
          muscleGroup: 'Chest',
          sets: 3,
          reps: '10',
          restSeconds: 60,
          targetWeight: 40,
          tracksWeight: true,
          notes: '',
        ),
    ],
    currentIndex: currentIndex,
    status: status,
    assignedAt: DateTime(2026, 11, 6),
  ).toWorkoutPlan(completedSetsByOrder: completedSets);
}

WorkoutPlan get _emptyPlan => const WorkoutPlan(
  id: 'empty',
  name: 'No Workout Assigned',
  focus: 'Ask your trainer to assign a plan',
  durationMinutes: 0,
  estimatedCalories: 0,
  level: '',
  completionPercent: 0,
  exercises: [],
);

Future<void> _pump(WidgetTester tester, WorkoutPlan plan) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutProvider.overrideWith((ref) async => plan),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const WorkoutDetailScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty: says nothing is assigned and offers no start', (
    tester,
  ) async {
    await _pump(tester, _emptyPlan);

    expect(find.text('No exercises assigned'), findsOneWidget);
    expect(find.text('Start Workout'), findsNothing);
  });

  testWidgets('active: the first exercise is open and the rest are locked', (
    tester,
  ) async {
    await _pump(tester, _plan(currentIndex: 0));

    expect(find.text('Exercise 1'), findsOneWidget);
    expect(find.text('Exercise 3'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);

    // One lock per exercise ahead of currentIndex, and none on the current
    // one.
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
  });

  testWidgets('locked: tapping a locked exercise is refused', (tester) async {
    await _pump(tester, _plan(currentIndex: 0));

    // The third row sits below the fold on a test-sized window.
    await tester.ensureVisible(find.text('Exercise 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise 3'));
    await tester.pumpAndSettle();

    expect(
      find.text('Finish the exercise before this one first.'),
      findsOneWidget,
    );
  });

  testWidgets('part way: earlier exercises unlock as the index advances', (
    tester,
  ) async {
    await _pump(tester, _plan(currentIndex: 2));

    // Only nothing is left ahead of index 2 in a three-exercise plan.
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('complete: finished exercises show a tick', (tester) async {
    await _pump(
      tester,
      _plan(currentIndex: 1, completedSets: {0: 3}),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('finished: no start button once the plan is done', (
    tester,
  ) async {
    await _pump(
      tester,
      _plan(
        currentIndex: 3,
        completedSets: {0: 3, 1: 3, 2: 3},
        status: AssignedPlanStatus.completed,
      ),
    );

    expect(find.text('Start Workout'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
  });

  testWidgets('skipped: the row says so and gives the reason', (tester) async {
    // The repository marks a skipped exercise when building the UI model; the
    // row has to surface the reason so the member sees what they told their
    // trainer.
    final plan = _plan(currentIndex: 1);
    final skipped = WorkoutPlan(
      id: plan.id,
      name: plan.name,
      focus: plan.focus,
      durationMinutes: plan.durationMinutes,
      estimatedCalories: plan.estimatedCalories,
      level: plan.level,
      completionPercent: plan.completionPercent,
      currentIndex: plan.currentIndex,
      status: plan.status,
      exercises: [
        plan.exercises.first.copyWith(
          isSkipped: true,
          skipReason: 'Equipment in use',
        ),
        ...plan.exercises.skip(1),
      ],
    );

    await _pump(tester, skipped);

    expect(find.textContaining('Skipped'), findsOneWidget);
    expect(find.textContaining('Equipment in use'), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
  });
}
