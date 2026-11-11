import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/features/group_classes/domain/booking_decision.dart';
import 'package:deepfitness/features/notifications/application/notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSession session({
  int capacity = 10,
  int bookedCount = 0,
  int waitlistCount = 0,
}) {
  return ClassSession(
    base: const BaseFields(id: 'session-1'),
    classId: 'class-1',
    capacity: capacity,
    bookedCount: bookedCount,
    waitlistCount: waitlistCount,
  );
}

Booking booking(BookingStatus status, {int position = 0}) {
  return Booking(
    base: const BaseFields(id: 'booking-1'),
    sessionId: 'session-1',
    memberId: 'member-1',
    status: status,
    position: position,
  );
}

void main() {
  group('booking capacity', () {
    test('a place is confirmed while there is room', () {
      final decision = BookingDecision.book(session(bookedCount: 3));
      expect(decision.status, BookingStatus.booked);
      expect(decision.bookedDelta, 1);
      expect(decision.waitlistDelta, 0);
      expect(decision.position, 0);
    });

    test('the last place is still a confirmed booking', () {
      final decision = BookingDecision.book(
        session(capacity: 10, bookedCount: 9),
      );
      expect(decision.status, BookingStatus.booked);
    });

    test('the next member after the last place is waitlisted', () {
      // This is the oversell case: the counter read inside the
      // transaction already includes the member who took place ten.
      final decision = BookingDecision.book(
        session(capacity: 10, bookedCount: 10),
      );
      expect(decision.status, BookingStatus.waitlisted);
      expect(decision.bookedDelta, 0);
      expect(decision.waitlistDelta, 1);
      expect(decision.position, 1);
    });

    test('waitlist positions count up from one', () {
      final decision = BookingDecision.book(
        session(capacity: 10, bookedCount: 10, waitlistCount: 4),
      );
      expect(decision.position, 5);
    });

    test('a session with no capacity waitlists everyone', () {
      final decision = BookingDecision.book(session(capacity: 0));
      expect(decision.status, BookingStatus.waitlisted);
    });

    test('a counter that has drifted above capacity still waitlists', () {
      final decision = BookingDecision.book(
        session(capacity: 10, bookedCount: 12),
      );
      expect(decision.status, BookingStatus.waitlisted);
    });
  });

  group('cancelling', () {
    test('giving up a booked place moves no counter here', () {
      // onBookingCancelled owns bookedCount on a cancellation: it is the
      // only writer that can see the waitlist in the same transaction.
      // Decrementing here as well would release the same place twice and
      // let the session oversell.
      final decision = BookingDecision.cancel(booking(BookingStatus.booked));
      expect(decision.bookedDelta, 0);
      expect(decision.waitlistDelta, 0);
    });

    test('a waitlisted booking frees a queue slot, not a place', () {
      // Decrementing bookedCount here would invent a place that was
      // never taken and let the class oversell.
      final decision = BookingDecision.cancel(
        booking(BookingStatus.waitlisted, position: 2),
      );
      expect(decision.bookedDelta, 0);
      expect(decision.waitlistDelta, -1);
    });
  });

  group('session state', () {
    test('reports places left', () {
      expect(session(capacity: 10, bookedCount: 4).placesLeft, 6);
    });

    test('never reports negative places', () {
      expect(session(capacity: 10, bookedCount: 12).placesLeft, 0);
    });

    test('is full once booked reaches capacity', () {
      expect(session(capacity: 10, bookedCount: 10).isFull, isTrue);
      expect(session(capacity: 10, bookedCount: 9).isFull, isFalse);
    });
  });

  group('Booking.idFor', () {
    test('is stable per member and session', () {
      expect(
        Booking.idFor(sessionId: 's1', memberId: 'm1'),
        Booking.idFor(sessionId: 's1', memberId: 'm1'),
      );
      expect(
        Booking.idFor(sessionId: 's1', memberId: 'm1'),
        isNot(Booking.idFor(sessionId: 's2', memberId: 'm1')),
      );
    });
  });

  group('video embed', () {
    GroupClass withVideo(VideoProvider provider) => GroupClass(
      base: const BaseFields(id: 'c1'),
      title: 'Yoga',
      videoProvider: provider,
      videoId: 'abc123',
    );

    test('builds a YouTube embed that plays inline', () {
      final url = withVideo(VideoProvider.youtube).embedUrl;
      expect(url, contains('youtube.com/embed/abc123'));
      // Without this the video takes over the screen on iOS, which is
      // the jump out of the app the document rules out.
      expect(url, contains('playsinline=1'));
    });

    test('builds a Vimeo embed', () {
      expect(
        withVideo(VideoProvider.vimeo).embedUrl,
        contains('player.vimeo.com/video/abc123'),
      );
    });

    test('an unknown provider falls back to YouTube', () {
      expect(VideoProvider.fromName('rumble'), VideoProvider.youtube);
    });
  });

  group('notification routing', () {
    test('an explicit route in the payload wins', () {
      expect(
        NotificationHandler.routeFor({'route': '/plan', 'type': 'anything'}),
        '/plan',
      );
    });

    test('a type maps to its screen', () {
      expect(
        NotificationHandler.routeFor({'type': 'class_reminder'}),
        '/classes',
      );
      expect(
        NotificationHandler.routeFor({'type': 'event_reminder'}),
        '/events',
      );
      expect(
        NotificationHandler.routeFor({'type': 'plan_assigned'}),
        '/plan',
      );
    });

    test('an unknown notification lands on the notices list', () {
      // Better than doing nothing: the announcement was mirrored there,
      // so there is always something to read.
      expect(NotificationHandler.routeFor({'type': 'something-new'}),
          '/notices');
      expect(NotificationHandler.routeFor(const {}), '/notices');
    });

    test('a route that is not a path is ignored', () {
      expect(
        NotificationHandler.routeFor({'route': 'https://evil.example'}),
        '/notices',
      );
    });
  });
}
