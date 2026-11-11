import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:deepfitness/features/group_classes/domain/booking_decision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.watch(firestoreProvider)),
);

/// Booking a place in a class session, and giving it back.
class BookingRepository extends BaseRepository {
  const BookingRepository(super.firestore);

  /// Upcoming sessions for one class, soonest first.
  Stream<List<ClassSession>> watchSessions(String classId, {DateTime? now}) {
    return notDeleted(
          firestore
              .collection(Collections.classSessions)
              .where('classId', isEqualTo: classId),
        )
        .where('startsAt', isGreaterThanOrEqualTo: now ?? DateTime.now())
        .orderBy('startsAt')
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassSession.fromFirestore(doc, null))
              .toList(growable: false),
        );
  }

  /// The member's active bookings, by session id.
  Stream<Map<String, Booking>> watchMyBookings(String memberId) {
    return firestore
        .collection(Collections.bookings)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) {
          final bookings = <String, Booking>{};
          for (final doc in snapshot.docs) {
            final booking = Booking.fromFirestore(doc, null);
            if (booking.isActive) bookings[booking.sessionId] = booking;
          }
          return bookings;
        });
  }

  /// Books a place, or joins the waitlist when the session is full.
  ///
  /// Runs in a transaction, as the document requires: the session is read
  /// and its counter written in the same atomic step as the booking. Two
  /// members tapping at the same instant therefore cannot both be handed
  /// the last place — the second transaction re-runs against the counter
  /// the first one wrote and lands on the waitlist.
  ///
  /// Returns the decision that was committed, so the screen can say which
  /// of the two happened.
  Future<BookingDecision> book({
    required String sessionId,
    required String memberId,
  }) {
    return guard(() async {
      return firestore.runTransaction<BookingDecision>((transaction) async {
        final sessionRef = firestore
            .collection(Collections.classSessions)
            .doc(sessionId);
        final bookingRef = firestore
            .collection(Collections.bookings)
            .doc(Booking.idFor(sessionId: sessionId, memberId: memberId));

        // Every read must come before any write in a Firestore
        // transaction, so both documents are fetched up front.
        final sessionSnapshot = await transaction.get(sessionRef);
        final existingSnapshot = await transaction.get(bookingRef);

        if (!sessionSnapshot.exists) {
          throw const RepositoryFailure(
            FailureKind.notFound,
            'That class is no longer scheduled.',
          );
        }

        final existing = existingSnapshot.exists
            ? Booking.fromFirestore(existingSnapshot, null)
            : null;
        if (existing != null && existing.isActive) {
          throw const RepositoryFailure(
            FailureKind.conflict,
            'You already have a place on this class.',
          );
        }

        final session = ClassSession.fromFirestore(sessionSnapshot, null);
        final decision = BookingDecision.book(session);

        transaction.set(
          bookingRef,
          Booking.create(
            sessionId: sessionId,
            memberId: memberId,
            status: decision.status,
            position: decision.position,
          ),
        );

        transaction.update(sessionRef, {
          'bookedCount': session.bookedCount + decision.bookedDelta,
          'waitlistCount': session.waitlistCount + decision.waitlistDelta,
          ...BaseFields.onUpdate(),
        });

        return decision;
      });
    });
  }

  /// Gives a place back and frees the counter it held.
  ///
  /// Also in a transaction, so the counter can never drift from the
  /// bookings behind it. Promoting the first waitlisted member is the
  /// `onBookingCancelled` function's work: it writes someone else's
  /// booking, which no client is allowed to do.
  Future<void> cancel({
    required String sessionId,
    required String memberId,
  }) {
    return guard(() async {
      await firestore.runTransaction((transaction) async {
        final sessionRef = firestore
            .collection(Collections.classSessions)
            .doc(sessionId);
        final bookingRef = firestore
            .collection(Collections.bookings)
            .doc(Booking.idFor(sessionId: sessionId, memberId: memberId));

        final bookingSnapshot = await transaction.get(bookingRef);
        final sessionSnapshot = await transaction.get(sessionRef);

        if (!bookingSnapshot.exists) return;
        final booking = Booking.fromFirestore(bookingSnapshot, null);
        if (!booking.isActive) return;

        final decision = BookingDecision.cancel(booking);

        // Only the status changes on the booking, which is all the
        // security rule lets a member write on their own.
        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          ...BaseFields.onUpdate(),
        });

        if (sessionSnapshot.exists) {
          final session = ClassSession.fromFirestore(sessionSnapshot, null);
          transaction.update(sessionRef, {
            // Clamped at zero: a counter that drifted below the real
            // number of bookings would hand out places that do not exist.
            'bookedCount':
                (session.bookedCount + decision.bookedDelta).clamp(0, 1 << 31),
            'waitlistCount': (session.waitlistCount + decision.waitlistDelta)
                .clamp(0, 1 << 31),
            ...BaseFields.onUpdate(),
          });
        }
      });
    });
  }
}
