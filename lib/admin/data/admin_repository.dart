import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/models/gym_event.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/paged_query.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(appFirebaseProvider)),
);

/// Guards every dashboard provider.
///
/// Admin, not staff: these providers back the dashboard, which the route guard
/// also limits to admins. A trainer reaches the same data through the trainer
/// app's own providers. The rules are the real control; this just avoids
/// firing queries that are certain to be denied.
Future<void> _requireAdmin(Ref ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (!session.isAuthenticated || !(session.role?.isAdmin ?? false)) {
    throw const RepositoryFailure(
      FailureKind.permissionDenied,
      'You do not have access to the dashboard.',
    );
  }
}

final adminEventsProvider = FutureProvider<List<GymEvent>>((ref) async {
  await _requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).fetchEvents();
});

final adminClassesProvider = FutureProvider<List<GroupClass>>((ref) async {
  await _requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).fetchClasses();
});

final adminSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  await _requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).fetchSessions();
});

final adminAnnouncementsProvider = FutureProvider<List<Announcement>>((
  ref,
) async {
  await _requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).fetchSentAnnouncements();
});

final adminMembersProvider = FutureProvider<List<Member>>((ref) async {
  await _requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).fetchMembers();
});

/// The member whose history the dashboard is showing.
final adminSelectedMemberProvider =
    NotifierProvider<AdminSelectedMemberController, Member?>(
      AdminSelectedMemberController.new,
    );

class AdminSelectedMemberController extends Notifier<Member?> {
  @override
  Member? build() => null;

  void select(Member? member) => state = member;
}

final adminMemberHistoryProvider = FutureProvider<List<CompletionLog>>((
  ref,
) async {
  await _requireAdmin(ref);
  final member = ref.watch(adminSelectedMemberProvider);
  if (member == null) return const [];
  return ref.watch(adminRepositoryProvider).fetchMemberHistory(member.id);
});

final adminSessionBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, sessionId) async {
      await _requireAdmin(ref);
      return ref.watch(adminRepositoryProvider).fetchBookings(sessionId);
    });

class AdminRepository {
  const AdminRepository(this._firebase);

  final AppFirebase _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  // ------------------------------------------------------------------ members

  Future<List<Member>> fetchMembers({int limit = 100}) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<Member>(
        query: _db
            .collection(FirestorePaths.members)
            .where('role', isEqualTo: 'member')
            .orderBy(BaseFields.createdAt, descending: true),
        fromDoc: Member.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading members');
  }

  /// A member's completed and skipped exercises, newest first.
  Future<List<CompletionLog>> fetchMemberHistory(
    String memberId, {
    int limit = 100,
  }) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<CompletionLog>(
        query: _db
            .collection(FirestorePaths.completionLogs)
            .where('memberId', isEqualTo: memberId)
            .orderBy('completedAt', descending: true),
        fromDoc: CompletionLog.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: "loading that member's history");
  }

  Future<List<AssignedPlan>> fetchMemberPlans(
    String memberId, {
    int limit = 20,
  }) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<AssignedPlan>(
        query: _db
            .collection(FirestorePaths.assignedPlans)
            .where('memberId', isEqualTo: memberId)
            .orderBy('scheduledDate', descending: true),
        fromDoc: AssignedPlan.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: "loading that member's plans");
  }

  Future<void> setMembership({
    required String memberId,
    required MembershipStatus status,
    DateTime? expiryDate,
  }) {
    return guard(() async {
      _firebase.requireUserId();
      await _db.collection(FirestorePaths.members).doc(memberId).update({
        'membershipStatus': status.name,
        'expiryDate': expiryDate == null
            ? null
            : Timestamp.fromDate(expiryDate),
        ...BaseFields.onUpdate(),
      });
    }, whileDoing: 'updating that membership');
  }

  /// Roles change through the callable alone — never by writing the field.
  Future<void> setUserRole({
    required String uid,
    required UserRole role,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
      await callable.call<Map<String, dynamic>>({
        'uid': uid,
        'role': role.name,
      });
    }, whileDoing: 'changing that role', timeout: const Duration(seconds: 30));
  }

  // ------------------------------------------------------------------- events

  Future<List<GymEvent>> fetchEvents({int limit = 50}) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<GymEvent>(
        query: _db
            .collection(FirestorePaths.events)
            .orderBy('startsAt', descending: true),
        fromDoc: GymEvent.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading events');
  }

  Future<void> saveEvent(GymEvent event, {String? id}) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final collection = _db.collection(FirestorePaths.events);
      if (id == null) {
        await collection.add({
          ...event.toFirestore(),
          ...BaseFields.onCreate(by: uid),
        });
      } else {
        await collection.doc(id).update({
          ...event.toFirestore(),
          ...BaseFields.onUpdate(),
        });
      }
    }, whileDoing: 'saving that event');
  }

  /// Soft delete: the event stops appearing, and its RSVPs stay on record.
  Future<void> deleteEvent(String id) {
    return guard(() async {
      _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.events)
          .doc(id)
          .update(BaseFields.onDelete());
    }, whileDoing: 'removing that event');
  }

  // ------------------------------------------------------------------ classes

  Future<List<GroupClass>> fetchClasses({int limit = 50}) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<GroupClass>(
        query: _db.collection(FirestorePaths.groupClasses).orderBy('title'),
        fromDoc: GroupClass.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading classes');
  }

  Future<void> saveClass(GroupClass groupClass, {String? id}) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final collection = _db.collection(FirestorePaths.groupClasses);
      if (id == null) {
        await collection.add({
          ...groupClass.toFirestore(),
          ...BaseFields.onCreate(by: uid),
        });
      } else {
        await collection.doc(id).update({
          ...groupClass.toFirestore(),
          ...BaseFields.onUpdate(),
        });
      }
    }, whileDoing: 'saving that class');
  }

  Future<void> deleteClass(String id) {
    return guard(() async {
      _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.groupClasses)
          .doc(id)
          .update(BaseFields.onDelete());
    }, whileDoing: 'removing that class');
  }

  Future<List<ClassSession>> fetchSessions({int limit = 50}) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<ClassSession>(
        query: _db
            .collection(FirestorePaths.classSessions)
            .orderBy('startsAt', descending: true),
        fromDoc: ClassSession.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading class times');
  }

  /// Creates a scheduled run of a class. Counters start at zero and are only
  /// ever moved by the booking transaction afterwards.
  Future<void> createSession({
    required GroupClass groupClass,
    required String instructor,
    required DateTime startsAt,
    required int capacity,
  }) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      if (capacity <= 0) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'A class needs at least one place.',
        );
      }
      await _db.collection(FirestorePaths.classSessions).add({
        'classId': groupClass.id,
        'classTitle': groupClass.title,
        'instructor': instructor,
        'startsAt': Timestamp.fromDate(startsAt),
        'capacity': capacity,
        'bookedCount': 0,
        'waitlistCount': 0,
        ...BaseFields.onCreate(by: uid),
      });
    }, whileDoing: 'scheduling that class');
  }

  Future<void> deleteSession(String id) {
    return guard(() async {
      _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.classSessions)
          .doc(id)
          .update(BaseFields.onDelete());
    }, whileDoing: 'removing that class time');
  }

  /// Who holds a place, and who is waiting, in waitlist order.
  Future<List<Booking>> fetchBookings(String sessionId) {
    return guard(() async {
      _firebase.requireUserId();
      final snapshot = await _db
          .collection(FirestorePaths.bookings)
          .where('sessionId', isEqualTo: sessionId)
          .where('status', whereIn: ['booked', 'waitlisted'])
          .orderBy('position')
          .get();
      return snapshot.docs.map(Booking.fromFirestore).toList();
    }, whileDoing: 'loading the booking list');
  }

  // ------------------------------------------------------------ announcements

  Future<List<Announcement>> fetchSentAnnouncements({int limit = 50}) {
    return guard(() async {
      _firebase.requireUserId();
      final page = await fetchPage<Announcement>(
        query: _db
            .collection(FirestorePaths.announcements)
            .orderBy('sentAt', descending: true),
        fromDoc: Announcement.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading sent announcements');
  }

  /// Sending is a callable: the fan-out needs admin credentials, and the
  /// mirror into `announcements` is written server-side so a client cannot
  /// fake a push that never went out.
  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    String? deepLink,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      if (title.trim().isEmpty || body.trim().isEmpty) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Give it a title and a message.',
        );
      }
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendAnnouncement',
      );
      await callable.call<Map<String, dynamic>>({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience.name,
        'deepLink': deepLink,
      });
    }, whileDoing: 'sending that announcement', timeout: const Duration(seconds: 45));
  }

  // ----------------------------------------------------------------- library

  Future<void> saveExercise(Exercise exercise, {String? id}) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final collection = _db.collection(FirestorePaths.exercises);
      if (id == null) {
        await collection.add({
          ...exercise.toFirestore(),
          ...BaseFields.onCreate(by: uid),
        });
      } else {
        await collection.doc(id).update({
          ...exercise.toFirestore(),
          ...BaseFields.onUpdate(),
        });
      }
    }, whileDoing: 'saving that exercise');
  }

  /// Soft delete only. A hard delete would orphan nothing — assigned plans
  /// snapshot their exercises — but the library is still an audit trail.
  Future<void> deleteExercise(String id) {
    return guard(() async {
      _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.exercises)
          .doc(id)
          .update(BaseFields.onDelete());
    }, whileDoing: 'removing that exercise');
  }
}
