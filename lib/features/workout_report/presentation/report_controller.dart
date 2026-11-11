import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/workout_report/data/report_repository.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The window the member has selected.
final reportRangeProvider =
    NotifierProvider<ReportRangeController, ReportRange>(
      ReportRangeController.new,
    );

class ReportRangeController extends Notifier<ReportRange> {
  @override
  ReportRange build() => ReportRange.week();

  void select(ReportRange range) => state = range;
}

/// The report for the selected window.
///
/// It depends on the range provider, so changing the selector re-runs the
/// single Firestore query and recomputes the maths.
final workoutReportProvider = FutureProvider<WorkoutReport>((ref) async {
  final range = ref.watch(reportRangeProvider);
  final memberId = ref.watch(authControllerProvider).value?.member?.id;

  if (memberId == null) {
    return WorkoutReport.from(range: range, logs: const []);
  }

  final logs = await ref
      .watch(reportRepositoryProvider)
      .logsInRange(memberId: memberId, range: range);

  return WorkoutReport.from(range: range, logs: logs);
});
