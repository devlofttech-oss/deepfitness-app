import 'package:deepfitness/core/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventRsvp.idFor', () {
    test('is derived from the event and member', () {
      expect(
        EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-1'),
        'evt-1_mem-1',
      );
    });

    test('is stable, so a second tap overwrites rather than duplicates', () {
      // One RSVP per member per event is enforced by the id rather than
      // left to the rules to catch after the fact.
      final first = EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-1');
      final second = EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-1');
      expect(first, second);
    });

    test('differs per member and per event', () {
      expect(
        EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-1'),
        isNot(EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-2')),
      );
      expect(
        EventRsvp.idFor(eventId: 'evt-1', memberId: 'mem-1'),
        isNot(EventRsvp.idFor(eventId: 'evt-2', memberId: 'mem-1')),
      );
    });
  });

  group('EventRsvp.create', () {
    test('stamps the member as the author', () {
      final data = EventRsvp.create(eventId: 'evt-1', memberId: 'mem-1');
      expect(data['memberId'], 'mem-1');
      expect(data['createdBy'], 'mem-1');
    });
  });
}
