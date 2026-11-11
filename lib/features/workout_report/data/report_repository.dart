import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(firestoreProvider)),
);

/// Reads the completion logs a report is derived from.
class ReportRepository extends BaseRepository {
  const ReportRepository(super.firestore);

  /// The member's logs inside [range], as a single query on `completedAt`.
  ///
  /// One query, not one per day: the document asks for the range to be a
  /// single read, and the maths is then done in Dart.
  ///
  /// The limit is a guard against a range so wide it would pull a year of
  /// documents onto the device; a member doing twenty exercises a day
  /// would reach it only after a hundred days.
  Future<List<CompletionLog>> logsInRange({
    required String memberId,
    required ReportRange range,
    int limit = 2000,
  }) {
    return guard(() async {
      final snapshot = await firestore
          .collection(Collections.completionLogs)
          .where('memberId', isEqualTo: memberId)
          .where('completedAt', isGreaterThanOrEqualTo: range.start)
          .where('completedAt', isLessThan: range.end)
          .orderBy('completedAt')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CompletionLog.fromFirestore(doc, null))
          .toList(growable: false);
    });
  }
}
