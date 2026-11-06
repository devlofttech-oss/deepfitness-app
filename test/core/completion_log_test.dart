import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_test/flutter_test.dart';

CompletionLog _log({
  List<CompletedSet> sets = const [],
  bool skipped = false,
  String? skipReason,
  bool tracksWeight = true,
}) {
  return CompletionLog(
    id: 'log1',
    memberId: 'member1',
    assignedPlanId: 'plan1',
    exerciseIndex: 0,
    exerciseId: 'bench',
    exerciseName: 'Bench Press',
    muscleGroup: 'Chest',
    setsPlanned: 3,
    setsDone: sets.length,
    sets: sets,
    skipped: skipped,
    skipReason: skipReason,
    completedAt: DateTime(2026, 11, 6),
    tracksWeight: tracksWeight,
  );
}

void main() {
  group('report maths', () {
    test('topWeight is the heaviest set', () {
      final log = _log(
        sets: const [
          CompletedSet(setNumber: 1, weight: 40, reps: 10),
          CompletedSet(setNumber: 2, weight: 55, reps: 8),
          CompletedSet(setNumber: 3, weight: 50, reps: 8),
        ],
      );

      expect(log.topWeight, 55);
    });

    test('bodyweight work reports no personal best', () {
      // Otherwise a "weight" typed against a press-up would show up in the
      // personal-bests list as if it were a lift.
      final log = _log(
        tracksWeight: false,
        sets: const [CompletedSet(setNumber: 1, weight: 20, reps: 15)],
      );

      expect(log.topWeight, 0);
    });

    test('a log with no sets has no best and no volume', () {
      expect(_log().topWeight, 0);
      expect(_log().volume, 0);
      expect(_log().totalReps, 0);
    });

    test('volume is weight times reps across every set', () {
      final log = _log(
        sets: const [
          CompletedSet(setNumber: 1, weight: 40, reps: 10),
          CompletedSet(setNumber: 2, weight: 50, reps: 8),
        ],
      );

      expect(log.volume, 400 + 400);
      expect(log.totalReps, 18);
    });
  });

  group('skip', () {
    test('a skip records the reason and no sets', () {
      final log = _log(skipped: true, skipReason: 'Equipment in use');

      expect(log.skipped, isTrue);
      expect(log.skipReason, 'Equipment in use');
      expect(log.setsDone, 0);
      expect(log.toFirestore()['skipReason'], 'Equipment in use');
    });

    test('a completion carries no skip reason', () {
      final log = _log(
        sets: const [CompletedSet(setNumber: 1, weight: 40, reps: 10)],
      );

      expect(log.skipped, isFalse);
      expect(log.skipReason, isNull);
    });
  });

  test('a set maps to and from the logging model', () {
    const log = ExerciseLog(setNumber: 2, weight: 45, reps: 9);
    final set = CompletedSet.fromLog(log);

    expect(set.setNumber, 2);
    expect(set.weight, 45);
    expect(set.reps, 9);

    final back = set.toExerciseLog();
    expect(back.completed, isTrue);
    expect(back.weight, 45);
  });

  test('a set read from an empty map defaults rather than throwing', () {
    final set = CompletedSet.fromMap(const {});

    expect(set.setNumber, 1);
    expect(set.weight, 0);
    expect(set.reps, 0);
  });

  test('the written document carries the derived report fields', () {
    final log = _log(
      sets: const [
        CompletedSet(setNumber: 1, weight: 40, reps: 10),
        CompletedSet(setNumber: 2, weight: 60, reps: 5),
      ],
    );

    final data = log.toFirestore();
    expect(data['topWeight'], 60);
    expect(data['volume'], 400 + 300);
    expect(data['exerciseName'], 'Bench Press');
    expect(data['setsDone'], 2);
  });
}
