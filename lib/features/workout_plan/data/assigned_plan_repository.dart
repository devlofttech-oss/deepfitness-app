import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assignedPlanRepositoryProvider = Provider<AssignedPlanRepository>(
  (ref) => AssignedPlanRepository(ref.watch(firestoreProvider)),
);

/// Reads a member's assigned plans and records their progress through one.
class AssignedPlanRepository extends BaseRepository {
  const AssignedPlanRepository(super.firestore);

  Query<Map<String, dynamic>> _forMember(String memberId) {
    return notDeleted(
      firestore
          .collection(Collections.assignedPlans)
          .where('memberId', isEqualTo: memberId),
    ).orderBy('assignedAt', descending: true);
  }

  /// Watches the member's current plan.
  ///
  /// The newest assignment wins: staff assigning a new plan replaces what
  /// the member sees on the home screen without anything being deleted.
  Stream<AssignedPlan?> watchCurrent(String memberId) {
    return _forMember(memberId).limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AssignedPlan.fromFirestore(snapshot.docs.first, null);
    });
  }

  /// One page of the member's plan history, newest first.
  Future<Page<AssignedPlan>> history(
    String memberId, {
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<AssignedPlan>(
      _forMember(memberId),
      map: (doc) => AssignedPlan.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  /// The logs written against one plan, oldest first.
  ///
  /// The plan document stores progress as a single index, so which of the
  /// finished exercises were skipped rather than completed is only known
  /// from the logs. The plan screen needs it to show the two apart.
  Stream<List<CompletionLog>> watchLogsForPlan({
    required String memberId,
    required String assignedPlanId,
  }) {
    return firestore
        .collection(Collections.completionLogs)
        .where('memberId', isEqualTo: memberId)
        .where('assignedPlanId', isEqualTo: assignedPlanId)
        .orderBy('completedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CompletionLog.fromFirestore(doc, null))
              .toList(growable: false),
        );
  }

  /// Records an exercise as completed or skipped and moves the unlock on.
  ///
  /// Both writes go in one batch, as the document requires. If they were
  /// separate, a failure between them would either advance the member past
  /// an exercise with no log behind it — making every report wrong — or
  /// log work the plan still shows as outstanding.
  ///
  /// A skip still advances. The member is never stuck on an exercise they
  /// cannot do, which is why the reason is required rather than the skip
  /// being refused.
  Future<void> recordOutcome({
    required AssignedPlan plan,
    required String memberId,
    required PlanExercise exercise,
    required int setsDone,
    required bool skipped,
    String? skipReason,
  }) {
    return guard(() async {
      assert(
        !skipped || (skipReason != null && skipReason.trim().isNotEmpty),
        'A skip must carry a reason.',
      );

      final batch = firestore.batch();

      batch.set(
        firestore.collection(Collections.completionLogs).doc(),
        CompletionLog.create(
          memberId: memberId,
          assignedPlanId: plan.id,
          exerciseName: exercise.name,
          setsDone: skipped ? 0 : setsDone,
          skipped: skipped,
          skipReason: skipReason?.trim(),
        ),
      );

      batch.update(
        firestore.collection(Collections.assignedPlans).doc(plan.id),
        plan.advanceUpdate(),
      );

      await batch.commit();
    });
  }
}
