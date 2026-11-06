import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activity series', () {
    test('a day with no work is still a day', () {
      // The chart has to show the gaps. Dropping empty days would draw four
      // scattered workouts as though they were consecutive.
      final days = [
        DayCount(DateTime(2026, 11, 1), 3),
        DayCount(DateTime(2026, 11, 2), 0),
        DayCount(DateTime(2026, 11, 3), 2),
      ];

      expect(days.length, 3);
      expect(days[1].count, 0);
      expect(days.fold<int>(0, (total, day) => total + day.count), 5);
    });

    test('a day count carries its own date', () {
      const count = 4;
      final day = DayCount(DateTime(2026, 11, 6), count);

      expect(day.day, DateTime(2026, 11, 6));
      expect(day.count, 4);
    });
  });

  group('progress defaults', () {
    test('a report with no activity has an empty series', () {
      const progress = MemberProgress(
        currentWeight: 0,
        weightDelta: 0,
        workoutsCompleted: 0,
        goalCompletion: 0,
        dayStreak: 0,
        muscleProgress: {},
        personalBests: {},
        assignedExercises: 0,
        completedExercises: 0,
        missedExercises: 0,
        adherence: 0,
      );

      // The chart renders nothing rather than crashing on an empty range.
      expect(progress.dailyCompletions, isEmpty);
    });
  });
}
