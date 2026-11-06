import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/models/gym_event.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSession _session({
  int capacity = 10,
  int bookedCount = 0,
  int waitlistCount = 0,
  DateTime? startsAt,
}) {
  return ClassSession(
    id: 'session1',
    classId: 'class1',
    classTitle: 'Spin',
    instructor: 'Sam',
    startsAt: startsAt ?? DateTime.now().add(const Duration(days: 1)),
    capacity: capacity,
    bookedCount: bookedCount,
    waitlistCount: waitlistCount,
  );
}

void main() {
  group('class session capacity', () {
    test('places left counts down as the class fills', () {
      expect(_session(bookedCount: 0).placesLeft, 10);
      expect(_session(bookedCount: 7).placesLeft, 3);
      expect(_session(bookedCount: 10).placesLeft, 0);
    });

    test('a full session reports no places', () {
      expect(_session(bookedCount: 10).isFull, isTrue);
      expect(_session(bookedCount: 9).isFull, isFalse);
    });

    test('an overbooked session clamps rather than going negative', () {
      // If a counter ever drifts past capacity, the UI must not offer -2
      // places.
      final session = _session(capacity: 10, bookedCount: 12);
      expect(session.placesLeft, 0);
      expect(session.isFull, isTrue);
    });

    test('a zero-capacity session is full', () {
      expect(_session(capacity: 0).isFull, isTrue);
      expect(_session(capacity: 0).placesLeft, 0);
    });

    test('a session in the past is marked past', () {
      expect(
        _session(
          startsAt: DateTime.now().subtract(const Duration(hours: 1)),
        ).isPast,
        isTrue,
      );
      expect(_session().isPast, isFalse);
    });
  });

  group('booking status', () {
    test('only a booked place holds a spot', () {
      expect(BookingStatus.booked.holdsAPlace, isTrue);
      expect(BookingStatus.waitlisted.holdsAPlace, isFalse);
      expect(BookingStatus.cancelled.holdsAPlace, isFalse);
    });

    test('a waitlisted place is still active', () {
      // Active decides whether the member sees "leave the waitlist" or
      // "book a place".
      expect(BookingStatus.waitlisted.isActive, isTrue);
      expect(BookingStatus.booked.isActive, isTrue);
      expect(BookingStatus.cancelled.isActive, isFalse);
    });

    test('an unknown stored status is treated as cancelled', () {
      // The safe default: a status nobody recognises must not hold a place.
      expect(BookingStatus.fromName('nonsense'), BookingStatus.cancelled);
      expect(BookingStatus.fromName(null), BookingStatus.cancelled);
    });

    test('the booking id ties a session to one member', () {
      expect(Booking.idFor('session1', 'member1'), 'session1_member1');
    });
  });

  group('video links', () {
    test('builds a YouTube embed that plays inline', () {
      final url = VideoProvider.youtube.embedUrl('abc123');
      expect(url, contains('youtube.com/embed/abc123'));
      expect(url, contains('playsinline=1'));
    });

    test('builds a Vimeo embed', () {
      expect(
        VideoProvider.vimeo.embedUrl('987'),
        'https://player.vimeo.com/video/987',
      );
    });

    test('an unknown provider falls back to YouTube', () {
      expect(VideoProvider.fromName('dailymotion'), VideoProvider.youtube);
      expect(VideoProvider.fromName(null), VideoProvider.youtube);
    });

    test('the watch URL differs from the embed URL', () {
      // The embed is what the in-app player loads; the watch URL is only for
      // sharing.
      expect(
        VideoProvider.youtube.watchUrl('abc123'),
        'https://www.youtube.com/watch?v=abc123',
      );
    });
  });

  group('events', () {
    GymEvent event({DateTime? startsAt}) => GymEvent(
      id: 'event1',
      title: 'Open Day',
      description: 'Come along.',
      startsAt: startsAt ?? DateTime.now().add(const Duration(days: 7)),
      venue: 'Main floor',
    );

    test('an RSVP id ties an event to one member', () {
      expect(EventRsvp.idFor('event1', 'member1'), 'event1_member1');
    });

    test('a past event is marked past', () {
      expect(
        event(
          startsAt: DateTime.now().subtract(const Duration(days: 1)),
        ).isPast,
        isTrue,
      );
      expect(event().isPast, isFalse);
    });

    test('copyWith carries the RSVP without losing the event', () {
      final updated = event().copyWith(hasRsvped: true, rsvpCount: 5);

      expect(updated.hasRsvped, isTrue);
      expect(updated.rsvpCount, 5);
      expect(updated.title, 'Open Day');
      expect(updated.venue, 'Main floor');
    });
  });

  group('announcement audiences', () {
    test('each audience maps to the topic sendAnnouncement publishes to', () {
      // These strings are the contract with functions/src/announcements.ts;
      // a rename on either side silently stops delivering.
      expect(AnnouncementAudience.all.topic, 'all');
      expect(AnnouncementAudience.members.topic, 'members');
      expect(AnnouncementAudience.trainers.topic, 'trainers');
    });

    test('an unknown stored audience falls back to everyone', () {
      expect(
        AnnouncementAudience.fromName('nonsense'),
        AnnouncementAudience.all,
      );
    });
  });
}
