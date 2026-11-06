import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

AssignedExercise _exercise(int order, {String? name, int sets = 3}) {
  return AssignedExercise(
    order: order,
    exerciseId: 'ex$order',
    name: name ?? 'Exercise $order',
    description: '',
    muscleGroup: 'Chest',
    sets: sets,
    reps: '10',
    restSeconds: 60,
    targetWeight: 40,
    tracksWeight: true,
    notes: '',
  );
}

AssignedPlan _plan({required int currentIndex, int exercises = 3}) {
  return AssignedPlan(
    id: 'plan1',
    memberId: 'member1',
    planId: 'template1',
    title: 'Push Day',
    focus: 'Chest',
    level: 'Intermediate',
    durationMinutes: 45,
    estimatedCalories: 320,
    scheduledDate: '2026-11-06',
    exercises: [for (var i = 0; i < exercises; i++) _exercise(i)],
    currentIndex: currentIndex,
    status: AssignedPlanStatus.active,
    assignedAt: DateTime(2026, 11, 6),
  );
}

void main() {
  group('sequential unlock', () {
    test('locks every exercise ahead of currentIndex', () {
      final plan = _plan(currentIndex: 1);

      expect(plan.isLockedAt(0), isFalse, reason: 'already done');
      expect(plan.isLockedAt(1), isFalse, reason: 'the current one');
      expect(plan.isLockedAt(2), isTrue, reason: 'not reached yet');
    });

    test('a fresh plan unlocks only the first exercise', () {
      final plan = _plan(currentIndex: 0);

      expect(plan.isLockedAt(0), isFalse);
      expect(plan.isLockedAt(1), isTrue);
      expect(plan.isLockedAt(2), isTrue);
    });

    test('currentExercise is null once the plan runs out', () {
      expect(_plan(currentIndex: 3).currentExercise, isNull);
      expect(_plan(currentIndex: 3).isFinished, isTrue);
      expect(_plan(currentIndex: 2).currentExercise?.order, 2);
    });

    test('carries the lock through to the UI model', () {
      final workout = _plan(currentIndex: 1).toWorkoutPlan();

      expect(workout.exercises[0].isLocked, isFalse);
      expect(workout.exercises[1].isLocked, isFalse);
      expect(workout.exercises[2].isLocked, isTrue);
      expect(workout.currentIndex, 1);
    });

    test('isUnlocked matches an exercise by its assignment key', () {
      final workout = _plan(currentIndex: 1).toWorkoutPlan();

      expect(workout.isUnlocked(workout.exercises[1]), isTrue);
      expect(workout.isUnlocked(workout.exercises[2]), isFalse);
    });

    test('indexOf finds the right one when two share an exercise id', () {
      // The same library exercise can appear twice in one plan, so matching on
      // the exercise id alone would find the wrong position.
      final plan = AssignedPlan(
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
          const AssignedExercise(
            order: 0,
            exerciseId: 'bench',
            name: 'Bench Press',
            description: '',
            muscleGroup: 'Chest',
            sets: 3,
            reps: '10',
            restSeconds: 60,
            targetWeight: 40,
            tracksWeight: true,
            notes: '',
          ),
          const AssignedExercise(
            order: 1,
            exerciseId: 'bench',
            name: 'Bench Press',
            description: '',
            muscleGroup: 'Chest',
            sets: 2,
            reps: '8',
            restSeconds: 90,
            targetWeight: 50,
            tracksWeight: true,
            notes: 'Heavier',
          ),
        ],
        currentIndex: 0,
        status: AssignedPlanStatus.active,
        assignedAt: DateTime(2026, 11, 6),
      );

      final workout = plan.toWorkoutPlan();
      expect(workout.indexOf(workout.exercises[1]), 1);
    });
  });

  group('completion percentage', () {
    test('is zero when nothing has been logged', () {
      expect(_plan(currentIndex: 0).toWorkoutPlan().completionPercent, 0);
    });

    test('counts completed sets against the plan total', () {
      // 9 sets planned across 3 exercises; 3 done.
      final workout = _plan(
        currentIndex: 1,
      ).toWorkoutPlan(completedSetsByOrder: {0: 3});

      expect(workout.completionPercent, closeTo(1 / 3, 0.001));
    });

    test('never exceeds 1 when more sets are logged than planned', () {
      final workout = _plan(
        currentIndex: 3,
      ).toWorkoutPlan(completedSetsByOrder: {0: 99, 1: 99, 2: 99});

      expect(workout.completionPercent, 1.0);
    });
  });

  group('status transitions', () {
    test('an active plan may move anywhere', () {
      expect(
        AssignedPlanStatus.active.canMoveTo(AssignedPlanStatus.completed),
        isTrue,
      );
      expect(
        AssignedPlanStatus.active.canMoveTo(AssignedPlanStatus.cancelled),
        isTrue,
      );
    });

    test('a completed plan may be reopened but not cancelled', () {
      expect(
        AssignedPlanStatus.completed.canMoveTo(AssignedPlanStatus.active),
        isTrue,
      );
      expect(
        AssignedPlanStatus.completed.canMoveTo(AssignedPlanStatus.cancelled),
        isFalse,
      );
    });

    test('a cancelled plan is final', () {
      expect(
        AssignedPlanStatus.cancelled.canMoveTo(AssignedPlanStatus.active),
        isFalse,
      );
      expect(
        AssignedPlanStatus.cancelled.canMoveTo(AssignedPlanStatus.cancelled),
        isTrue,
      );
    });

    test('an unknown stored status falls back to active', () {
      expect(AssignedPlanStatus.fromName('nonsense'), AssignedPlanStatus.active);
      expect(AssignedPlanStatus.fromName(null), AssignedPlanStatus.active);
    });
  });

  group('assignment snapshot', () {
    test('copies the exercise rather than referencing it', () {
      const library = Exercise(
        id: 'squat',
        name: 'Squat',
        description: 'Knees out',
        muscleGroup: 'Legs',
        sets: 4,
        reps: '8',
        restSeconds: 90,
        icon: 'legs',
        notes: '',
        tracksWeight: true,
        targetWeight: 60,
      );

      final snapshot = AssignedExercise.snapshot(library, 0);

      expect(snapshot.name, 'Squat');
      expect(snapshot.exerciseId, 'squat');
      expect(snapshot.sets, 4);
      expect(snapshot.targetWeight, 60);
      // The copy survives the library row being renamed afterwards.
      expect(snapshot.toMap()['name'], 'Squat');
    });

    test('fills in sane defaults for an underspecified exercise', () {
      const sparse = Exercise(
        id: 'plank',
        name: 'Plank',
        description: '',
        muscleGroup: 'Core',
        sets: 0,
        reps: '',
        restSeconds: 0,
        icon: 'core',
        notes: '',
        tracksWeight: false,
        targetWeight: 25,
      );

      final snapshot = AssignedExercise.snapshot(sparse, 2);

      expect(snapshot.sets, 3);
      expect(snapshot.reps, '10');
      expect(snapshot.restSeconds, 60);
      expect(snapshot.notes, isNotEmpty, reason: 'a default coaching note');
      // Bodyweight work carries no target weight even if one was set.
      expect(snapshot.targetWeight, 0);
    });

    test('round-trips through a map', () {
      final original = _exercise(1, name: 'Row', sets: 5);
      final restored = AssignedExercise.fromMap(original.toMap());

      expect(restored.name, 'Row');
      expect(restored.sets, 5);
      expect(restored.order, 1);
      expect(restored.exerciseId, original.exerciseId);
    });

    test('defaults every field when the map is empty', () {
      final restored = AssignedExercise.fromMap(const {}, order: 4);

      expect(restored.name, 'Exercise');
      expect(restored.sets, 3);
      expect(restored.order, 4);
      expect(restored.muscleGroup, 'Full Body');
    });
  });
}
