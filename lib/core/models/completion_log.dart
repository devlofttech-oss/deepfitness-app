import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// One exercise finished or skipped. Append-only, and the source for every
/// report: completion rate, streaks and volume all derive from these, so
/// nothing else needs its own storage.
class CompletionLog {
  const CompletionLog({
    required this.base,
    required this.memberId,
    required this.assignedPlanId,
    required this.exerciseName,
    required this.setsDone,
    required this.skipped,
    this.skipReason,
    this.completedAt,
  });

  factory CompletionLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return CompletionLog(
      base: BaseFields.fromMap(snapshot.id, data),
      memberId: (data['memberId'] as String?) ?? '',
      assignedPlanId: (data['assignedPlanId'] as String?) ?? '',
      exerciseName: (data['exerciseName'] as String?) ?? '',
      setsDone: (data['setsDone'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as bool?) ?? false,
      skipReason: data['skipReason'] as String?,
      completedAt: readTimestamp(data['completedAt']),
    );
  }

  final BaseFields base;
  final String memberId;
  final String assignedPlanId;
  final String exerciseName;
  final int setsDone;
  final bool skipped;
  final String? skipReason;
  final DateTime? completedAt;

  String get id => base.id;

  /// The document written when an exercise is completed or skipped.
  ///
  /// `completedAt` is a server timestamp: reports are ordered and bucketed
  /// by it, and a device with the wrong clock would land in the wrong week.
  static Map<String, Object?> create({
    required String memberId,
    required String assignedPlanId,
    required String exerciseName,
    required int setsDone,
    required bool skipped,
    String? skipReason,
  }) {
    return {
      'memberId': memberId,
      'assignedPlanId': assignedPlanId,
      'exerciseName': exerciseName,
      'setsDone': setsDone,
      'skipped': skipped,
      if (skipReason != null) 'skipReason': skipReason,
      'completedAt': FieldValue.serverTimestamp(),
      ...BaseFields.onCreate(createdBy: memberId),
    };
  }
}
