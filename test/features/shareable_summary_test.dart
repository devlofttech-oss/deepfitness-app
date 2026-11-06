import 'package:deepfitness/app/theme.dart';
import 'package:deepfitness/features/progress/presentation/shareable_summary.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MemberProgress _progress({
  Map<String, int> bests = const {},
  int completed = 12,
  int streak = 4,
  double adherence = 0.75,
}) {
  return MemberProgress(
    currentWeight: 78,
    weightDelta: -1.2,
    workoutsCompleted: 6,
    goalCompletion: .5,
    dayStreak: streak,
    muscleProgress: const {},
    personalBests: bests,
    assignedExercises: 16,
    completedExercises: completed,
    missedExercises: 4,
    adherence: adherence,
  );
}

Future<void> _pump(
  WidgetTester tester,
  GlobalKey key,
  MemberProgress progress,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: ShareableSummary(
            boundaryKey: key,
            memberName: 'Alex Kumar',
            progress: progress,
            rangeLabel: 'This month',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the member, the range and the headline numbers', (
    tester,
  ) async {
    await _pump(tester, GlobalKey(), _progress());

    expect(find.text('Alex Kumar'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('lists at most three personal bests', (tester) async {
    await _pump(
      tester,
      GlobalKey(),
      _progress(
        bests: const {
          'Bench Press': 80,
          'Squat': 120,
          'Deadlift': 140,
          'Overhead Press': 50,
        },
      ),
    );

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Deadlift'), findsOneWidget);
    // The fourth would push the card past a shareable height.
    expect(find.text('Overhead Press'), findsNothing);
  });

  testWidgets('hides the bests section when there are none', (tester) async {
    await _pump(tester, GlobalKey(), _progress());

    expect(find.text('Personal bests'), findsNothing);
  });

  testWidgets('captures the card to PNG bytes', (tester) async {
    final key = GlobalKey();
    await _pump(tester, key, _progress(bests: const {'Squat': 120}));

    // PNG encoding is real async work, which the test binding's fake clock
    // never completes — it has to run on the real one.
    final bytes = await tester.runAsync(
      () => captureSummary(key, pixelRatio: 1),
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(0));
    // PNG magic number, so this is a real image and not an empty buffer.
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('returns null rather than throwing when nothing is mounted', (
    tester,
  ) async {
    expect(await captureSummary(GlobalKey()), isNull);
  });
}
