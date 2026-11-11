import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';

/// One day's activity, for the chart.
class DailyActivity {
  const DailyActivity({
    required this.day,
    required this.completed,
    required this.skipped,
    required this.sets,
  });

  final DateTime day;
  final int completed;
  final int skipped;
  final int sets;

  bool get hasActivity => completed > 0 || skipped > 0;
}

/// Everything the reports screen shows, derived in Dart from the logs.
///
/// Nothing here is stored. The document is explicit that one log feeds
/// every report, so completion rate, streaks and volume are computed on
/// the device rather than kept in a second place that could disagree.
class WorkoutReport {
  const WorkoutReport({
    required this.range,
    required this.completed,
    required this.skipped,
    required this.totalSets,
    required this.currentStreak,
    required this.longestStreak,
    required this.daily,
  });

  /// Builds the report from the logs in [range].
  ///
  /// [today] is injectable so the streak, which depends on what day it is,
  /// can be tested without waiting for midnight.
  factory WorkoutReport.from({
    required ReportRange range,
    required List<CompletionLog> logs,
    DateTime? today,
  }) {
    final byDay = <DateTime, List<CompletionLog>>{};
    var completed = 0;
    var skipped = 0;
    var totalSets = 0;

    for (final log in logs) {
      final at = log.completedAt;
      // A log whose server timestamp has not landed yet cannot be placed
      // on a day, so it is left out rather than guessed at.
      if (at == null) continue;

      if (log.skipped) {
        skipped++;
      } else {
        completed++;
        totalSets += log.setsDone;
      }
      byDay.putIfAbsent(startOfDay(at), () => []).add(log);
    }

    final daily = <DailyActivity>[];
    for (var day = range.start;
        day.isBefore(range.end);
        day = day.add(const Duration(days: 1))) {
      final onDay = byDay[startOfDay(day)] ?? const <CompletionLog>[];
      daily.add(
        DailyActivity(
          day: startOfDay(day),
          completed: onDay.where((log) => !log.skipped).length,
          skipped: onDay.where((log) => log.skipped).length,
          sets: onDay
              .where((log) => !log.skipped)
              .fold(0, (sum, log) => sum + log.setsDone),
        ),
      );
    }

    final activeDays = byDay.keys.toSet();
    return WorkoutReport(
      range: range,
      completed: completed,
      skipped: skipped,
      totalSets: totalSets,
      currentStreak: _currentStreak(activeDays, today ?? DateTime.now()),
      longestStreak: _longestStreak(activeDays),
      daily: daily,
    );
  }

  final ReportRange range;
  final int completed;
  final int skipped;
  final int totalSets;
  final int currentStreak;
  final int longestStreak;
  final List<DailyActivity> daily;

  int get totalLogged => completed + skipped;

  /// Share of finished exercises that were actually done, 0 to 1.
  ///
  /// The denominator is what the member got through, not what was
  /// assigned: an untouched exercise is still ahead of them and counting
  /// it as a failure would punish someone midway through a plan.
  double get completionRate =>
      totalLogged == 0 ? 0 : completed / totalLogged;

  int get activeDays => daily.where((day) => day.hasActivity).length;

  bool get isEmpty => totalLogged == 0;

  /// Days up to and including today with at least one log.
  ///
  /// A day that is still in progress does not break the run, so a streak
  /// counted before this evening's session reads the same as after it.
  static int _currentStreak(Set<DateTime> activeDays, DateTime today) {
    if (activeDays.isEmpty) return 0;

    var cursor = startOfDay(today);
    if (!activeDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(cursor)) return 0;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest unbroken run of active days anywhere in the window.
  static int _longestStreak(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort();
    var longest = 1;
    var run = 1;

    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }
    return longest;
  }
}
