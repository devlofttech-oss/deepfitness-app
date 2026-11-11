import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:flutter_test/flutter_test.dart';

PlanExercise exercise(String name) =>
    PlanExercise(exerciseId: name.toLowerCase(), name: name, sets: 3, reps: 10);

AssignedPlan plan({
  int currentIndex = 0,
  int count = 3,
  AssignedPlanStatus status = AssignedPlanStatus.active,
}) {
  return AssignedPlan(
    base: const BaseFields(id: 'plan-1'),
    memberId: 'member-1',
    planId: 'template-1',
    title: 'Push day',
    exercises: List.generate(count, (i) => exercise('Exercise ${i + 1}')),
    currentIndex: currentIndex,
    status: status,
  );
}

void main() {
  group('sequential unlock', () {
    test('only the first exercise is open on a fresh plan', () {
      final fresh = plan();
      expect(fresh.isLocked(0), isFalse);
      expect(fresh.isLocked(1), isTrue);
      expect(fresh.isLocked(2), isTrue);
    });

    test('an exercise unlocks once the one before it is behind the index', () {
      final midway = plan(currentIndex: 1);
      expect(midway.isLocked(0), isFalse);
      expect(midway.isLocked(1), isFalse);
      expect(midway.isLocked(2), isTrue);
    });

    test('the current exercise is the one at the index', () {
      expect(plan(currentIndex: 1).currentExercise?.name, 'Exercise 2');
    });

    test('there is nothing current once the plan is finished', () {
      final done = plan(currentIndex: 3);
      expect(done.isComplete, isTrue);
      expect(done.currentExercise, isNull);
    });

    test('an empty plan is neither locked nor in progress', () {
      final empty = plan(count: 0);
      expect(empty.isEmpty, isTrue);
      expect(empty.currentExercise, isNull);
      expect(empty.progress, 0);
    });
  });

  group('advanceUpdate', () {
    test('moves the index on by one', () {
      expect(plan(currentIndex: 0).advanceUpdate()['currentIndex'], 1);
    });

    test('writes only the three fields the security rule permits', () {
      expect(
        plan().advanceUpdate().keys.toSet(),
        {'currentIndex', 'status', 'updatedAt'},
      );
    });

    test('stays active while exercises remain', () {
      expect(plan(currentIndex: 0).advanceUpdate()['status'], 'active');
    });

    test('completes the plan on the last exercise', () {
      // Advancing from the final index must flip the status, otherwise a
      // finished plan would sit on the home screen for ever.
      expect(plan(currentIndex: 2).advanceUpdate()['status'], 'completed');
    });
  });

  group('progress', () {
    test('is the fraction of exercises behind the member', () {
      expect(plan(currentIndex: 0).progress, 0);
      expect(plan(currentIndex: 3).progress, 1);
      expect(plan(currentIndex: 1, count: 4).progress, 0.25);
    });

    test('does not exceed one if the index overshoots', () {
      // A plan shortened by staff after assignment would otherwise read
      // as more than complete.
      expect(plan(currentIndex: 5, count: 3).progress, 1);
    });
  });

  group('defensive reads', () {
    test('a plan missing every optional field still builds', () {
      // Documents written by an older build will not carry the newer
      // fields, and the app is already live.
      final raw = AssignedPlan(
        base: const BaseFields(id: 'x'),
        memberId: '',
        planId: '',
        title: '',
        exercises: const [],
        currentIndex: 0,
        status: AssignedPlanStatus.active,
      );
      expect(raw.isEmpty, isTrue);
      expect(raw.isComplete, isFalse);
    });

    test('an unknown status falls back to active', () {
      expect(AssignedPlanStatus.fromName('nonsense'),
          AssignedPlanStatus.active);
    });
  });
}
