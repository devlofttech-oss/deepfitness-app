import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// A gym event, public to every signed-in member.
class Event {
  const Event({
    required this.base,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.startsAt,
    this.venue = '',
  });

  factory Event.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Event(
      base: BaseFields.fromMap(snapshot.id, data),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      startsAt: readTimestamp(data['startsAt']),
      venue: (data['venue'] as String?) ?? '',
    );
  }

  final BaseFields base;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? startsAt;
  final String venue;

  String get id => base.id;

  Map<String, Object?> toFirestore() => {
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'startsAt': startsAt,
    'venue': venue,
  };
}

/// One member saying they are coming. One document per member per event.
class EventRsvp {
  const EventRsvp({
    required this.base,
    required this.eventId,
    required this.memberId,
  });

  factory EventRsvp.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return EventRsvp(
      base: BaseFields.fromMap(snapshot.id, data),
      eventId: (data['eventId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
    );
  }

  final BaseFields base;
  final String eventId;
  final String memberId;

  String get id => base.id;

  /// The document id, derived rather than random.
  ///
  /// One RSVP per member per event is a rule, and a deterministic id makes
  /// it structural: a second tap overwrites the same document instead of
  /// creating a duplicate the rules would have to catch.
  static String idFor({required String eventId, required String memberId}) =>
      '${eventId}_$memberId';

  static Map<String, Object?> create({
    required String eventId,
    required String memberId,
  }) {
    return {
      'eventId': eventId,
      'memberId': memberId,
      ...BaseFields.onCreate(createdBy: memberId),
    };
  }
}
