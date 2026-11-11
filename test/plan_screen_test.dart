import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/features/workout_plan/presentation/plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AssignedPlan plan({required int currentIndex, int count = 3}) {
  return AssignedPlan(
    base: const BaseFields(id: 'plan-1'),
    memberId: 'member-1',
    planId: 'template-1',
    title: 'Push day',
    exercises: List.generate(
      count,
      (i) => PlanExercise(
        exerciseId: 'e$i',
        name: 'Exercise ${i + 1}',
        sets: 3,
        reps: 10,
      ),
    ),
    currentIndex: currentIndex,
    status: AssignedPlanStatus.active,
  );
}

CompletionLog log({required bool skipped}) {
  return CompletionLog(
    base: const BaseFields(id: 'log'),
    memberId: 'member-1',
    assignedPlanId: 'plan-1',
    exerciseName: 'Exercise 1',
    setsDone: skipped ? 0 : 3,
    skipped: skipped,
  );
}

Future<void> pumpList(
  WidgetTester tester, {
  required AssignedPlan assigned,
  List<CompletionLog> logs = const [],
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: PlanExerciseList(plan: assigned, logs: logs),
      ),
    ),
  );
}

void main() {
  testWidgets('a fresh plan shows the first exercise active', (tester) async {
    await pumpList(tester, assigned: plan(currentIndex: 0));

    expect(find.text('3 sets × 10 reps'), findsWidgets);
    expect(find.text('UP NEXT'), findsOneWidget);
  });

  testWidgets('later exercises are locked', (tester) async {
    await pumpList(tester, assigned: plan(currentIndex: 0));

    expect(find.text('Unlocks in sequence'), findsNWidgets(2));
    // Two locked rows, each with a glyph and a badge icon.
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(4));
  });

  testWidgets('a finished exercise reads as completed', (tester) async {
    await pumpList(
      tester,
      assigned: plan(currentIndex: 1),
      logs: [log(skipped: false)],
    );

    expect(find.text('DONE'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('a skipped exercise is shown apart from a completed one', (
    tester,
  ) async {
    // The plan document only stores an index, so this distinction comes
    // from the completion log and would be lost without it.
    await pumpList(
      tester,
      assigned: plan(currentIndex: 1),
      logs: [log(skipped: true)],
    );

    expect(find.text('SKIPPED'), findsOneWidget);
    expect(find.text('DONE'), findsNothing);
  });

  testWidgets('a complete plan says so and leaves nothing active', (
    tester,
  ) async {
    await pumpList(
      tester,
      assigned: plan(currentIndex: 3),
      logs: [
        log(skipped: false),
        log(skipped: false),
        log(skipped: false),
      ],
    );

    expect(find.text('COMPLETE'), findsWidgets);
    expect(find.text('UP NEXT'), findsNothing);
  });

  testWidgets('an empty plan renders just the header', (tester) async {
    await pumpList(tester, assigned: plan(currentIndex: 0, count: 0));

    expect(find.text('PUSH DAY'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('only the active exercise is tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PlanExerciseList(
            plan: plan(currentIndex: 1),
            logs: [log(skipped: false)],
            onExerciseTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('EXERCISE 3'));
    await tester.pump();
    expect(taps, 0, reason: 'a locked exercise must not open');

    await tester.tap(find.text('EXERCISE 2'));
    await tester.pump();
    expect(taps, 1);
  });
}
