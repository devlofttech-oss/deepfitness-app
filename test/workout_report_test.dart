import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 11, 11);

CompletionLog log({
  required int daysAgo,
  bool skipped = false,
  int sets = 3,
}) {
  return CompletionLog(
    base: const BaseFields(id: 'log'),
    memberId: 'member-1',
    assignedPlanId: 'plan-1',
    exerciseName: 'Squat',
    setsDone: skipped ? 0 : sets,
    skipped: skipped,
    completedAt: _today.subtract(Duration(days: daysAgo)).add(
      const Duration(hours: 10),
    ),
  );
}

WorkoutReport report(List<CompletionLog> logs) {
  return WorkoutReport.from(
    range: ReportRange.week(_today),
    logs: logs,
    today: _today,
  );
}

void main() {
  group('ReportRange', () {
    test('a week covers seven whole days ending tonight', () {
      final range = ReportRange.week(_today);
      expect(range.days, 7);
      expect(range.start, DateTime(2026, 11, 5));
      expect(range.end, DateTime(2026, 11, 12));
    });

    test('a month covers thirty days', () {
      expect(ReportRange.month(_today).days, 30);
    });

    test('a custom range includes both end dates', () {
      final range = ReportRange.custom(
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 3),
      );
      expect(range.days, 3);
    });

    test('a custom range given backwards is put in order', () {
      final range = ReportRange.custom(
        from: DateTime(2026, 11, 3),
        to: DateTime(2026, 11, 1),
      );
      expect(range.start, DateTime(2026, 11, 1));
      expect(range.days, 3);
    });
  });

  group('completion rate', () {
    test('is completed over everything logged', () {
      final result = report([
        log(daysAgo: 0),
        log(daysAgo: 0),
        log(daysAgo: 0, skipped: true),
      ]);
      expect(result.completed, 2);
      expect(result.skipped, 1);
      expect(result.completionRate, closeTo(2 / 3, 0.0001));
    });

    test('is zero, not a crash, when nothing is logged', () {
      final result = report([]);
      expect(result.completionRate, 0);
      expect(result.isEmpty, isTrue);
    });

    test('a skip contributes no sets', () {
      final result = report([log(daysAgo: 0, skipped: true, sets: 5)]);
      expect(result.totalSets, 0);
    });
  });

  group('sets completed', () {
    test('sums the sets across the window', () {
      final result = report([
        log(daysAgo: 0, sets: 3),
        log(daysAgo: 1, sets: 4),
      ]);
      expect(result.totalSets, 7);
    });
  });

  group('streaks', () {
    test('counts back from today', () {
      final result = report([
        log(daysAgo: 0),
        log(daysAgo: 1),
        log(daysAgo: 2),
      ]);
      expect(result.currentStreak, 3);
    });

    test('a day off breaks the run', () {
      final result = report([
        log(daysAgo: 0),
        log(daysAgo: 2),
        log(daysAgo: 3),
      ]);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 2);
    });

    test('a streak ending yesterday still counts while today is young', () {
      // Checking the streak before this evening's session must not read
      // as zero, or the number would flicker through every day.
      final result = report([log(daysAgo: 1), log(daysAgo: 2)]);
      expect(result.currentStreak, 2);
    });

    test('nothing in the last two days is no current streak', () {
      final result = report([log(daysAgo: 3), log(daysAgo: 4)]);
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 2);
    });

    test('several logs on one day count as one day', () {
      final result = report([
        log(daysAgo: 0),
        log(daysAgo: 0),
        log(daysAgo: 0),
      ]);
      expect(result.currentStreak, 1);
    });

    test('a skipped exercise still counts as showing up', () {
      final result = report([log(daysAgo: 0, skipped: true)]);
      expect(result.currentStreak, 1);
    });
  });

  group('daily series', () {
    test('has one entry per day in the range, including empty days', () {
      final result = report([log(daysAgo: 0, sets: 3)]);
      expect(result.daily.length, 7);
      expect(result.daily.where((day) => day.hasActivity).length, 1);
      expect(result.daily.last.sets, 3);
    });

    test('is in date order, oldest first', () {
      final result = report([]);
      expect(result.daily.first.day.isBefore(result.daily.last.day), isTrue);
    });

    test('counts active days', () {
      final result = report([log(daysAgo: 0), log(daysAgo: 3)]);
      expect(result.activeDays, 2);
    });
  });

  group('defensive reads', () {
    test('a log whose server timestamp has not landed is left out', () {
      // completedAt is null for the moment between the write and the
      // server stamping it; it cannot be placed on a day.
      final pending = CompletionLog(
        base: const BaseFields(id: 'pending'),
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
      );
      final result = report([pending, log(daysAgo: 0)]);
      expect(result.completed, 1);
    });
  });
}
