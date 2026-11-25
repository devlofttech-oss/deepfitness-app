import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/exercise.dart';
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

  group('demonstration media', () {
    Exercise libraryExercise({
      List<String> photoUrls = const [],
      String? videoUrl,
      String? posterUrl,
    }) {
      return Exercise(
        base: const BaseFields(id: '0184'),
        name: 'Hyperextension',
        photoUrls: photoUrls,
        videoUrl: videoUrl,
        posterUrl: posterUrl,
      );
    }

    test('the snapshot carries the media across', () {
      final snapshot = PlanExercise.snapshot(
        libraryExercise(
          videoUrl: 'https://cdn/video/0184.mp4',
          posterUrl: 'https://cdn/poster/0184.webp',
        ),
      );

      expect(snapshot.videoUrl, 'https://cdn/video/0184.mp4');
      expect(snapshot.posterUrl, 'https://cdn/poster/0184.webp');
    });

    test('the media survives a round trip through Firestore', () {
      final before = PlanExercise.snapshot(
        libraryExercise(
          videoUrl: 'https://cdn/video/0184.mp4',
          posterUrl: 'https://cdn/poster/0184.webp',
        ),
      );
      final after = PlanExercise.fromMap(
        before.toMap().cast<String, dynamic>(),
      );

      expect(after.videoUrl, before.videoUrl);
      expect(after.posterUrl, before.posterUrl);
    });

    test('an uploaded photo wins over the imported poster', () {
      // Uploading one is a deliberate act by a trainer; the poster that
      // came with the animation pack is only ever a default.
      final overridden = libraryExercise(
        photoUrls: const ['https://storage/custom.jpg'],
        posterUrl: 'https://cdn/poster/0184.webp',
      );

      expect(overridden.stillUrl, 'https://storage/custom.jpg');
      expect(
        PlanExercise.snapshot(overridden).stillUrl,
        'https://storage/custom.jpg',
      );
    });

    test('the poster is used when nothing was uploaded', () {
      final imported = libraryExercise(posterUrl: 'https://cdn/poster/0184.webp');

      expect(imported.stillUrl, 'https://cdn/poster/0184.webp');
      expect(
        PlanExercise.snapshot(imported).stillUrl,
        'https://cdn/poster/0184.webp',
      );
    });

    test('an exercise with no media at all has no still', () {
      expect(libraryExercise().stillUrl, isNull);
      expect(PlanExercise.snapshot(libraryExercise()).stillUrl, isNull);
    });
  });

  group('numbers that arrived as strings', () {
    // The seeded plan in the live project stores reps as "8", and "45s" for
    // a plank. A `as num?` cast throws on those rather than returning null,
    // so the whole plan stream failed and every member saw "Could not load
    // your plan" with nothing in the logs to say why.
    test('a plan exercise written with a string rep count still parses', () {
      final parsed = PlanExercise.fromMap(const <String, dynamic>{
        'exerciseId': 'bench-press',
        'name': 'Bench Press',
        'sets': 4,
        'reps': '8',
      });

      expect(parsed.name, 'Bench Press');
      expect(parsed.sets, 4);
      expect(parsed.reps, 8);
    });

    test('a duration in the reps field reads as its leading number', () {
      final plank = PlanExercise.fromMap(const <String, dynamic>{
        'exerciseId': 'plank',
        'name': 'Plank',
        'sets': 3,
        'reps': '45s',
      });

      expect(plank.reps, 45);
    });

    test('an unparseable value falls back instead of throwing', () {
      final odd = PlanExercise.fromMap(const <String, dynamic>{
        'exerciseId': 'x',
        'name': 'X',
        'sets': 'as many as you like',
        'reps': null,
      });

      expect(odd.sets, 3);
      expect(odd.reps, 10);
    });

    test('a whole plan of string-typed exercises parses', () {
      final plan = AssignedPlan.fromMap(const <String, dynamic>{
        'memberId': 'member-1',
        'planId': 'push-day',
        'title': 'Push Day',
        'currentIndex': 0,
        'status': 'active',
        'exercises': [
          {'exerciseId': 'bench-press', 'name': 'Bench Press', 'sets': 4, 'reps': '8'},
          {'exerciseId': 'plank', 'name': 'Plank', 'sets': 3, 'reps': '45s'},
        ],
      }, 'plan-1');

      expect(plan.exercises, hasLength(2));
      expect(plan.exercises.map((e) => e.reps), [8, 45]);
    });
  });
}
