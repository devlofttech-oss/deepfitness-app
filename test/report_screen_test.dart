import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:deepfitness/features/workout_report/presentation/report_controller.dart';
import 'package:deepfitness/features/workout_report/presentation/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which range the report was asked for, so the test can show
/// that tapping a chip re-runs the query rather than only restyling.
late List<ReportRangeKind> requested;

Future<void> pumpReports(WidgetTester tester) async {
  requested = [];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutReportProvider.overrideWith((ref) async {
          final range = ref.watch(reportRangeProvider);
          requested.add(range.kind);
          return WorkoutReport.from(range: range, logs: const []);
        }),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ReportScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the week and asks for it once', (tester) async {
    await pumpReports(tester);

    expect(find.text('WEEK'), findsOneWidget);
    expect(find.text('MONTH'), findsOneWidget);
    expect(find.text('CUSTOM'), findsOneWidget);
    expect(requested, [ReportRangeKind.week]);
  });

  testWidgets('tapping Month re-runs the query for the month', (tester) async {
    await pumpReports(tester);

    await tester.tap(find.text('MONTH'));
    await tester.pumpAndSettle();

    expect(requested, [ReportRangeKind.week, ReportRangeKind.month]);
  });

  testWidgets('an empty period says so rather than drawing a blank chart', (
    tester,
  ) async {
    await pumpReports(tester);

    expect(
      find.textContaining('NOTHING LOGGED IN THIS PERIOD'),
      findsOneWidget,
    );
  });

  testWidgets('the share action is hidden while there is nothing to share', (
    tester,
  ) async {
    await pumpReports(tester);

    expect(find.byIcon(Icons.ios_share), findsNothing);
  });

  testWidgets('a period with logs shows the tiles and the share action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutReportProvider.overrideWith(
            (ref) async => WorkoutReport(
              range: ReportRange.week(DateTime(2026, 11, 11)),
              completed: 3,
              skipped: 1,
              totalSets: 9,
              currentStreak: 2,
              longestStreak: 4,
              daily: const [],
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('best 4'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
  });
}
