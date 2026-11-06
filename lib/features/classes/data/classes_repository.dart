import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/repositories/paged_query.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepository(ref.watch(appFirebaseProvider)),
);

final groupClassesProvider = FutureProvider<List<GroupClass>>((ref) async {
  await _requireSignedIn(ref);
  return ref.watch(classesRepositoryProvider).fetchClasses();
});

/// Sessions starting from now, with this member's booking folded in.
final upcomingSessionsProvider = FutureProvider<List<ClassSession>>((
  ref,
) async {
  await _requireSignedIn(ref);
  return ref.watch(classesRepositoryProvider).fetchUpcomingSessions();
});

Future<void> _requireSignedIn(Ref ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (!session.isAuthenticated) {
    throw const RepositoryFailure(
      FailureKind.unauthenticated,
      'You are not logged in.',
    );
  }
}

final selectedClassProvider =
    NotifierProvider<SelectedClassController, GroupClass?>(
      SelectedClassController.new,
    );

class SelectedClassController extends Notifier<GroupClass?> {
  @override
  GroupClass? build() => null;

  void select(GroupClass value) => state = value;
}

/// What a booking attempt did, so the screen can say "booked" or "you are
/// number 3 on the waitlist" without re-reading anything.
class BookingOutcome {
  const BookingOutcome({required this.status, required this.position});

  final BookingStatus status;
  final int position;

  bool get isBooked => status == BookingStatus.booked;
}

class ClassesRepository {
  const ClassesRepository(this._firebase);

  final AppFirebase _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  Future<List<GroupClass>> fetchClasses({int limit = defaultPageSize}) {
    return guard(() async {
      _firebase.requireConfigured();
      final page = await fetchPage<GroupClass>(
        query: _db.collection(FirestorePaths.groupClasses).orderBy('title'),
        fromDoc: GroupClass.fromFirestore,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading classes');
  }

  /// Scheduled runs from now on, soonest first.
  ///
  /// [classId] narrows it to one class's sessions.
  Future<List<ClassSession>> fetchUpcomingSessions({
    String? classId,
    int limit = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return guard(() async {
      final uid = _firebase.requireUserId();

      var query = _db
          .collection(FirestorePaths.classSessions)
          .where(
            'startsAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          );
      if (classId != null) {
        query = query.where('classId', isEqualTo: classId);
      }

      final page = await fetchPage<ClassSession>(
        query: query.orderBy('startsAt'),
        fromDoc: ClassSession.fromFirestore,
        startAfter: startAfter,
        limit: limit,
      );

      if (page.items.isEmpty) return page.items;

      final mine = await _myBookings(
        uid,
        page.items.map((session) => session.id).toList(),
      );

      return [
        for (final session in page.items)
          session.copyWith(myBooking: mine[session.id]),
      ];
    }, whileDoing: 'loading class times');
  }

  Future<Map<String, Booking>> _myBookings(
    String uid,
    List<String> sessionIds,
  ) async {
    final bookings = <String, Booking>{};

    for (final batch in chunked(sessionIds)) {
      final snapshot = await _db
          .collection(FirestorePaths.bookings)
          .where('memberId', isEqualTo: uid)
          .where('sessionId', whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        if (booking.status.isActive) bookings[booking.sessionId] = booking;
      }
    }

    return bookings;
  }

  /// Books a place, or joins the waitlist when the session is full.
  ///
  /// The counter and the booking are written together in a transaction. Two
  /// members tapping at the same instant would otherwise both read the same
  /// `bookedCount`, both believe a place was free, and oversell the last one.
  Future<BookingOutcome> book(ClassSession session, {String? memberName}) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final sessionRef = _db
          .collection(FirestorePaths.classSessions)
          .doc(session.id);
      final bookingRef = _db
          .collection(FirestorePaths.bookings)
          .doc(Booking.idFor(session.id, uid));

      return _db.runTransaction<BookingOutcome>((tx) async {
        final sessionDoc = await tx.get(sessionRef);
        if (!sessionDoc.exists) {
          throw const RepositoryFailure(
            FailureKind.notFound,
            'That class time is no longer available.',
          );
        }

        final data = sessionDoc.data() ?? const <String, dynamic>{};
        final startsAt = Val.toDate(data['startsAt']);
        if (startsAt.isBefore(DateTime.now())) {
          throw const RepositoryFailure(
            FailureKind.invalid,
            'That class has already started.',
          );
        }

        final existing = await tx.get(bookingRef);
        final existingStatus = existing.exists
            ? BookingStatus.fromName(existing.data()?['status'])
            : null;
        if (existingStatus != null && existingStatus.isActive) {
          throw const RepositoryFailure(
            FailureKind.conflict,
            'You already have a place in that class.',
          );
        }

        final capacity = Val.toInt(data['capacity']);
        final bookedCount = Val.toInt(data['bookedCount']);
        final waitlistCount = Val.toInt(data['waitlistCount']);
        final hasRoom = bookedCount < capacity;

        final status = hasRoom
            ? BookingStatus.booked
            : BookingStatus.waitlisted;
        final position = hasRoom ? 0 : waitlistCount + 1;

        tx.set(bookingRef, {
          'sessionId': session.id,
          'memberId': uid,
          'status': status.name,
          'position': position,
          'memberName': memberName,
          ...BaseFields.onCreate(by: uid),
        });

        tx.update(sessionRef, {
          if (hasRoom) 'bookedCount': bookedCount + 1,
          if (!hasRoom) 'waitlistCount': waitlistCount + 1,
          ...BaseFields.onUpdate(),
        });

        return BookingOutcome(status: status, position: position);
      });
    }, whileDoing: 'booking your place');
  }

  /// Gives up a place.
  ///
  /// A booked place is only marked cancelled here: `onBookingCancelled` moves
  /// the counters and promotes the first waitlisted member, so doing it here
  /// too would decrement twice. A waitlisted place has no such trigger, so its
  /// counter is handled in this transaction.
  Future<void> cancelBooking(ClassSession session) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final sessionRef = _db
          .collection(FirestorePaths.classSessions)
          .doc(session.id);
      final bookingRef = _db
          .collection(FirestorePaths.bookings)
          .doc(Booking.idFor(session.id, uid));

      await _db.runTransaction((tx) async {
        final booking = await tx.get(bookingRef);
        if (!booking.exists) {
          throw const RepositoryFailure(
            FailureKind.notFound,
            'You do not have a place in that class.',
          );
        }

        final status = BookingStatus.fromName(booking.data()?['status']);
        if (!status.isActive) return;

        if (status == BookingStatus.waitlisted) {
          final sessionDoc = await tx.get(sessionRef);
          final waitlistCount = Val.toInt(sessionDoc.data()?['waitlistCount']);
          tx.update(sessionRef, {
            'waitlistCount': waitlistCount > 0 ? waitlistCount - 1 : 0,
            ...BaseFields.onUpdate(),
          });
        }

        tx.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'position': 0,
          ...BaseFields.onUpdate(),
        });
      });
    }, whileDoing: 'cancelling your place');
  }
}
