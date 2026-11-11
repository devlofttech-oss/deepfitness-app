import 'package:deepfitness/admin/domain/plan_assignment.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/workout_plan.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise exercise(String id, String name, {int sets = 3, int reps = 10}) {
  return Exercise(
    base: BaseFields(id: id),
    name: name,
    muscleGroup: 'Legs',
    description: 'Do it well',
    defaultSets: sets,
    defaultReps: reps,
  );
}

WorkoutPlan plan(List<String> refs) {
  return WorkoutPlan(
    base: const BaseFields(id: 'plan-1'),
    title: 'Leg day',
    exerciseRefs: refs,
  );
}

void main() {
  group('snapshotExercises', () {
    test('follows the order of the plan, not the library', () {
      // The order is the unlock order, so getting it from the library
      // would silently reshuffle what the member works through.
      final result = snapshotExercises(
        plan: plan(['c', 'a', 'b']),
        library: [
          exercise('a', 'Squat'),
          exercise('b', 'Lunge'),
          exercise('c', 'Deadlift'),
        ],
      );

      expect(
        result.map((item) => item.name).toList(),
        ['Deadlift', 'Squat', 'Lunge'],
      );
    });

    test('copies the details rather than referencing them', () {
      final result = snapshotExercises(
        plan: plan(['a']),
        library: [exercise('a', 'Squat', sets: 4, reps: 8)],
      );

      expect(result.single.exerciseId, 'a');
      expect(result.single.name, 'Squat');
      expect(result.single.sets, 4);
      expect(result.single.reps, 8);
      expect(result.single.description, 'Do it well');
    });

    test('drops an exercise deleted from the library since', () {
      // Assigning a blank in its place would leave the member stuck on
      // an exercise with no name and no instructions.
      final result = snapshotExercises(
        plan: plan(['a', 'gone', 'b']),
        library: [exercise('a', 'Squat'), exercise('b', 'Lunge')],
      );

      expect(result.length, 2);
      expect(result.map((item) => item.name), ['Squat', 'Lunge']);
    });

    test('an empty library yields an empty assignment', () {
      expect(snapshotExercises(plan: plan(['a']), library: []), isEmpty);
    });

    test('round trips through the map it is stored as', () {
      final original = snapshotExercises(
        plan: plan(['a']),
        library: [exercise('a', 'Squat', sets: 5, reps: 5)],
      ).single;

      final restored = PlanExercise.fromMap(original.toMap());
      expect(restored.exerciseId, 'a');
      expect(restored.name, 'Squat');
      expect(restored.sets, 5);
      expect(restored.reps, 5);
    });
  });
}
