import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';

/// What a booking attempt should write.
///
/// Kept apart from Firestore so the capacity rule — the thing that decides
/// whether two members tapping at once can oversell the last place — can
/// be tested on its own.
class BookingDecision {
  const BookingDecision({
    required this.status,
    required this.position,
    required this.bookedDelta,
    required this.waitlistDelta,
  });

  final BookingStatus status;

  /// Place in the queue, 1-based; zero for a confirmed booking.
  final int position;

  final int bookedDelta;
  final int waitlistDelta;

  bool get isWaitlisted => status == BookingStatus.waitlisted;

  /// Decides from the session as it was read *inside* the transaction.
  ///
  /// The counters must come from the transactional read, not from a
  /// snapshot the screen is holding: the whole point is that a stale
  /// `bookedCount` cannot be used to claim a place that has gone.
  static BookingDecision book(ClassSession session) {
    if (session.bookedCount < session.capacity) {
      return const BookingDecision(
        status: BookingStatus.booked,
        position: 0,
        bookedDelta: 1,
        waitlistDelta: 0,
      );
    }

    return BookingDecision(
      status: BookingStatus.waitlisted,
      position: session.waitlistCount + 1,
      bookedDelta: 0,
      waitlistDelta: 1,
    );
  }

  /// Decides what cancelling releases.
  ///
  /// Giving up a booked place moves no counter here. The
  /// `onBookingCancelled` trigger owns `bookedCount` on a cancellation,
  /// because only it can see the waitlist in the same transaction: with
  /// somebody waiting the place is handed straight on and the count does
  /// not change, and with nobody waiting the trigger releases it. If this
  /// decremented as well the two would both act on the same place and the
  /// session would oversell.
  ///
  /// Leaving a waitlist is different: no trigger watches it, so the queue
  /// counter is this client's to move.
  static BookingDecision cancel(Booking booking) {
    return BookingDecision(
      status: BookingStatus.cancelled,
      position: 0,
      bookedDelta: 0,
      waitlistDelta: booking.status == BookingStatus.waitlisted ? -1 : 0,
    );
  }
}
