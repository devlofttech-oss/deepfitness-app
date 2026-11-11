import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(firestoreProvider)),
);

/// Upcoming events, and the member's own RSVPs.
class EventRepository extends BaseRepository {
  const EventRepository(super.firestore);

  /// One page of upcoming events, soonest first.
  ///
  /// Filtered to `startsAt >= now` so a finished event drops off without
  /// anyone having to tidy it up.
  Future<Page<Event>> upcoming({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    DateTime? now,
  }) {
    final query = notDeleted(firestore.collection(Collections.events))
        .where(
          'startsAt',
          isGreaterThanOrEqualTo: now ?? DateTime.now(),
        )
        .orderBy('startsAt');

    return paginate<Event>(
      query,
      map: (doc) => Event.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }

  /// One event, for a deep link straight into the detail screen.
  Future<Event?> find(String id) {
    return guard(() async {
      final snapshot = await firestore
          .collection(Collections.events)
          .doc(id)
          .get();
      if (!snapshot.exists) return null;
      final event = Event.fromFirestore(snapshot, null);
      return event.base.isDeleted ? null : event;
    });
  }

  /// The ids of the events this member has said they are coming to.
  Stream<Set<String>> watchMyRsvps(String memberId) {
    return firestore
        .collection(Collections.eventRsvps)
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['eventId'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  /// Says the member is coming. Writing to a derived id makes a second
  /// tap idempotent rather than a duplicate.
  Future<void> rsvp({required String eventId, required String memberId}) {
    return guard(() async {
      await firestore
          .collection(Collections.eventRsvps)
          .doc(EventRsvp.idFor(eventId: eventId, memberId: memberId))
          .set(EventRsvp.create(eventId: eventId, memberId: memberId));
    });
  }

  /// Withdraws the RSVP. A hard delete, because the rules allow a member
  /// to remove only their own and there is no history worth keeping.
  Future<void> cancelRsvp({
    required String eventId,
    required String memberId,
  }) {
    return guard(() async {
      await firestore
          .collection(Collections.eventRsvps)
          .doc(EventRsvp.idFor(eventId: eventId, memberId: memberId))
          .delete();
    });
  }
}
