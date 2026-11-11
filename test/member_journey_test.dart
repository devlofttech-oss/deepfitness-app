import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// The member's path through the app, end to end at the domain level:
/// an assigned plan, worked through exercise by exercise, feeding the
/// report. The document names this as the integration case that matters.
///
/// The Firestore round trip is covered separately by the rules tests;
/// what is checked here is that the four pieces agree with each other —
/// the unlock, the log each step writes, and the numbers that come out.
void main() {
  final today = DateTime(2026, 11, 11);

  AssignedPlan assign(int count) {
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
      currentIndex: 0,
      status: AssignedPlanStatus.active,
    );
  }

  /// Applies what `recordOutcome` writes, without Firestore: the log, and
  /// the advance the same batch makes to the plan.
  (AssignedPlan, CompletionLog) step(
    AssignedPlan plan, {
    required bool skipped,
    int setsDone = 3,
    String? reason,
  }) {
    final exercise = plan.currentExercise!;
    final update = plan.advanceUpdate();

    final log = CompletionLog(
      base: const BaseFields(id: 'log'),
      memberId: plan.memberId,
      assignedPlanId: plan.id,
      exerciseName: exercise.name,
      setsDone: skipped ? 0 : setsDone,
      skipped: skipped,
      skipReason: reason,
      completedAt: today.add(const Duration(hours: 9)),
    );

    final advanced = AssignedPlan(
      base: plan.base,
      memberId: plan.memberId,
      planId: plan.planId,
      title: plan.title,
      exercises: plan.exercises,
      currentIndex: update['currentIndex']! as int,
      status: AssignedPlanStatus.fromName(update['status']),
      assignedAt: plan.assignedAt,
    );

    return (advanced, log);
  }

  test('a member works through a plan and the report follows', () {
    var plan = assign(4);
    final logs = <CompletionLog>[];

    expect(plan.currentExercise?.name, 'Exercise 1');
    expect(plan.isLocked(1), isTrue, reason: 'only the first is open');

    // Two done.
    for (var i = 0; i < 2; i++) {
      final (next, log) = step(plan, skipped: false);
      plan = next;
      logs.add(log);
    }

    // One skipped, with a reason. It must still advance.
    final (afterSkip, skipLog) = step(
      plan,
      skipped: true,
      reason: 'Equipment was busy',
    );
    plan = afterSkip;
    logs.add(skipLog);

    expect(plan.currentIndex, 3);
    expect(plan.isComplete, isFalse);
    expect(plan.currentExercise?.name, 'Exercise 4');

    // The last one finishes the plan.
    final (finished, lastLog) = step(plan, skipped: false);
    plan = finished;
    logs.add(lastLog);

    expect(plan.isComplete, isTrue);
    expect(plan.status, AssignedPlanStatus.completed);
    expect(plan.currentExercise, isNull);
    expect(plan.progress, 1);

    // Four exercises, four logs: no step advanced without recording one,
    // which is what the single batch exists to guarantee.
    expect(logs.length, 4);

    final report = WorkoutReport.from(
      range: ReportRange.week(today),
      logs: logs,
      today: today,
    );

    expect(report.completed, 3);
    expect(report.skipped, 1);
    expect(report.completionRate, closeTo(0.75, 0.0001));
    expect(report.totalSets, 9, reason: 'the skip contributes none');
    expect(report.currentStreak, 1);
    expect(report.activeDays, 1);
  });

  test('a skip keeps its reason all the way into the log', () {
    final (_, log) = step(
      assign(2),
      skipped: true,
      reason: 'Injury or pain',
    );

    expect(log.skipped, isTrue);
    expect(log.skipReason, 'Injury or pain');
    expect(log.setsDone, 0);
  });

  test('an empty plan reports nothing rather than dividing by zero', () {
    final report = WorkoutReport.from(
      range: ReportRange.week(today),
      logs: const [],
      today: today,
    );

    expect(report.isEmpty, isTrue);
    expect(report.completionRate, 0);
    expect(report.currentStreak, 0);
  });
}
