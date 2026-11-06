import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/gym_event.dart';
import 'package:deepfitness/core/repositories/paged_query.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(ref.watch(appFirebaseProvider)),
);

/// Upcoming events, with this member's RSVP folded in.
final upcomingEventsProvider = FutureProvider<List<GymEvent>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (!session.isAuthenticated) {
    throw const RepositoryFailure(
      FailureKind.unauthenticated,
      'You are not logged in.',
    );
  }
  return ref.watch(eventsRepositoryProvider).fetchUpcoming();
});

final selectedEventProvider = NotifierProvider<SelectedEventController, GymEvent?>(
  SelectedEventController.new,
);

class SelectedEventController extends Notifier<GymEvent?> {
  @override
  GymEvent? build() => null;

  void select(GymEvent event) => state = event;
}

class EventsRepository {
  const EventsRepository(this._firebase);

  final AppFirebase _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  /// Events starting from now, soonest first, one page at a time.
  Future<List<GymEvent>> fetchUpcoming({
    int limit = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return guard(() async {
      final uid = _firebase.requireUserId();

      final page = await fetchPage<GymEvent>(
        query: _db
            .collection(FirestorePaths.events)
            .where(
              'startsAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                Val.startOfDay(DateTime.now()),
              ),
            )
            .orderBy('startsAt'),
        fromDoc: GymEvent.fromFirestore,
        startAfter: startAfter,
        limit: limit,
      );

      if (page.items.isEmpty) return page.items;

      // One read for the member's RSVPs rather than one per event.
      final mine = await _myRsvpEventIds(
        uid,
        page.items.map((event) => event.id).toList(),
      );

      return [
        for (final event in page.items)
          event.copyWith(hasRsvped: mine.contains(event.id)),
      ];
    }, whileDoing: 'loading events');
  }

  Future<Set<String>> _myRsvpEventIds(String uid, List<String> eventIds) async {
    final found = <String>{};

    // whereIn takes at most 30 values, so a long page is split.
    for (final batch in chunked(eventIds)) {
      final snapshot = await _db
          .collection(FirestorePaths.eventRsvps)
          .where('memberId', isEqualTo: uid)
          .where('eventId', whereIn: batch)
          .get();
      found.addAll(
        snapshot.docs.map((doc) => Val.toText(doc.data()['eventId'])),
      );
    }

    return found;
  }

  /// One RSVP per member per event, enforced by the document id rather than
  /// by a query that could race with itself.
  Future<void> rsvp(GymEvent event) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.eventRsvps)
          .doc(EventRsvp.idFor(event.id, uid))
          .set({
            'eventId': event.id,
            'memberId': uid,
            ...BaseFields.onCreate(by: uid),
          });
    }, whileDoing: 'saving your RSVP');
  }

  Future<void> cancelRsvp(GymEvent event) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      await _db
          .collection(FirestorePaths.eventRsvps)
          .doc(EventRsvp.idFor(event.id, uid))
          .delete();
    }, whileDoing: 'cancelling your RSVP');
  }
}
