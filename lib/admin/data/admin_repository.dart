import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:deepfitness/admin/domain/plan_assignment.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/models/workout_plan.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instance,
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// Everything the dashboard writes.
///
/// It shares the models and the base repository with the app, so a change
/// to how a document is shaped reaches both at once. What it does not
/// share is permission: every write here is allowed only because the
/// caller's token carries the admin or trainer claim, and the rules — not
/// this class — are what enforce that.
class AdminRepository extends BaseRepository {
  const AdminRepository(super.firestore, this._functions);

  final FirebaseFunctions _functions;

  // ---------------------------------------------------------------- members

  /// The member roll, newest first.
  Future<Page<Member>> members({
    int limit = 25,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<Member>(
      notDeleted(
        firestore.collection(Collections.members),
      ).orderBy('joinedAt', descending: true),
      map: (doc) => Member.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  /// One member's workout history, newest first.
  Future<Page<CompletionLog>> memberHistory(
    String memberId, {
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<CompletionLog>(
      firestore
          .collection(Collections.completionLogs)
          .where('memberId', isEqualTo: memberId)
          .orderBy('completedAt', descending: true),
      map: (doc) => CompletionLog.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  /// Sets a member's membership window.
  ///
  /// Staff-only by the rules: this is exactly the pair of fields a member
  /// is forbidden from writing about themselves.
  Future<void> setMembership({
    required String memberId,
    required MembershipStatus status,
    DateTime? expiryDate,
  }) {
    return guard(() async {
      await firestore.collection(Collections.members).doc(memberId).update({
        'membershipStatus': status.name,
        if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate),
        ...BaseFields.onUpdate(),
      });
    });
  }

  /// Changes a member's role.
  ///
  /// Goes through the `setUserRole` callable, never a document write: the
  /// role lives in a custom claim on the token, and a field in Firestore
  /// would be a copy the rules do not read.
  Future<void> setRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      await _functions.httpsCallable('setUserRole').call<void>({
        'uid': uid,
        'role': role.name,
      });
    } on FirebaseFunctionsException catch (error) {
      throw RepositoryFailure(
        error.code == 'permission-denied'
            ? FailureKind.permissionDenied
            : FailureKind.unknown,
        error.message ?? 'Could not change that role.',
        cause: error,
      );
    }
  }

  // -------------------------------------------------------------- exercises

  Future<Page<Exercise>> exercises({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<Exercise>(
      notDeleted(firestore.collection(Collections.exercises)).orderBy('name'),
      map: (doc) => Exercise.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<void> saveExercise(Exercise exercise, {required String authorId}) {
    return guard(() async {
      final collection = firestore.collection(Collections.exercises);
      if (exercise.id.isEmpty) {
        await collection.add({
          ...exercise.toFirestore(),
          ...BaseFields.onCreate(createdBy: authorId),
        });
      } else {
        await collection.doc(exercise.id).update({
          ...exercise.toFirestore(),
          ...BaseFields.onUpdate(),
        });
      }
    });
  }

  /// Soft delete. The exercise stops appearing in the library and every
  /// assignment that snapshotted it is untouched.
  Future<void> deleteExercise(String id) {
    return guard(() async {
      await firestore
          .collection(Collections.exercises)
          .doc(id)
          .update(BaseFields.onDelete());
    });
  }

  // ------------------------------------------------------------------ plans

  Future<Page<WorkoutPlan>> plans({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<WorkoutPlan>(
      notDeleted(
        firestore.collection(Collections.workoutPlans),
      ).orderBy('title'),
      map: (doc) => WorkoutPlan.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  Future<void> savePlan(WorkoutPlan plan, {required String authorId}) {
    return guard(() async {
      final collection = firestore.collection(Collections.workoutPlans);
      if (plan.id.isEmpty) {
        await collection.add({
          ...plan.toFirestore(),
          ...BaseFields.onCreate(createdBy: authorId),
        });
      } else {
        await collection.doc(plan.id).update({
          ...plan.toFirestore(),
          ...BaseFields.onUpdate(),
        });
      }
    });
  }

  Future<void> deletePlan(String id) {
    return guard(() async {
      await firestore
          .collection(Collections.workoutPlans)
          .doc(id)
          .update(BaseFields.onDelete());
    });
  }

  // ------------------------------------------------------------- assignment

  /// Assigns a plan to a member, snapshotting the exercises.
  ///
  /// The snapshot is the point: the assignment copies the details it
  /// needs, so renaming "Squat" in the library afterwards does not
  /// rewrite what this member has already done.
  Future<void> assignPlan({
    required WorkoutPlan plan,
    required List<Exercise> library,
    required String memberId,
    required String authorId,
  }) {
    return guard(() async {
      final snapshot = snapshotExercises(plan: plan, library: library)
          .map((exercise) => exercise.toMap())
          .toList(growable: false);

      await firestore.collection(Collections.assignedPlans).add({
        'memberId': memberId,
        'planId': plan.id,
        'title': plan.title,
        'exercises': snapshot,
        'currentIndex': 0,
        'status': AssignedPlanStatus.active.name,
        'assignedAt': FieldValue.serverTimestamp(),
        ...BaseFields.onCreate(createdBy: authorId),
      });
    });
  }

  // ----------------------------------------------------------------- events

  Future<void> saveEvent(Event event, {required String authorId}) {
    return guard(() async {
      final collection = firestore.collection(Collections.events);
      final data = {
        ...event.toFirestore(),
        if (event.startsAt != null)
          'startsAt': Timestamp.fromDate(event.startsAt!),
      };
      if (event.id.isEmpty) {
        await collection.add({
          ...data,
          ...BaseFields.onCreate(createdBy: authorId),
        });
      } else {
        await collection.doc(event.id).update({
          ...data,
          ...BaseFields.onUpdate(),
        });
      }
    });
  }

  // ---------------------------------------------------------------- classes

  Future<void> saveClassSession({
    required String classId,
    required String instructor,
    required DateTime startsAt,
    required int capacity,
    required String authorId,
  }) {
    return guard(() async {
      await firestore.collection(Collections.classSessions).add({
        'classId': classId,
        'instructor': instructor,
        'startsAt': Timestamp.fromDate(startsAt),
        'capacity': capacity,
        // Counters start at zero and only ever move inside a booking
        // transaction, so they are set here and never written again
        // from the dashboard.
        'bookedCount': 0,
        'waitlistCount': 0,
        ...BaseFields.onCreate(createdBy: authorId),
      });
    });
  }

  /// Everyone holding a place or a queue slot on one session.
  Future<Page<Map<String, dynamic>>> sessionBookings(
    String sessionId, {
    int limit = 100,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<Map<String, dynamic>>(
      firestore
          .collection(Collections.bookings)
          .where('sessionId', isEqualTo: sessionId)
          .where('status', whereIn: ['booked', 'waitlisted'])
          .orderBy('position'),
      map: (doc) => {'id': doc.id, ...doc.data()},
      limit: limit,
      startAfter: startAfter,
    );
  }

  // ---------------------------------------------------------- announcements

  /// Sends a broadcast.
  ///
  /// Through the callable, never a document write: the client cannot
  /// reach the tokens, and the rules make `announcements` read-only so
  /// the mirror is written by the function with the Admin SDK.
  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String audience,
  }) async {
    try {
      await _functions.httpsCallable('sendAnnouncement').call<void>({
        'title': title,
        'body': body,
        'audience': audience,
      });
    } on FirebaseFunctionsException catch (error) {
      throw RepositoryFailure(
        error.code == 'permission-denied'
            ? FailureKind.permissionDenied
            : FailureKind.unknown,
        error.message ?? 'Could not send that announcement.',
        cause: error,
      );
    }
  }
}
