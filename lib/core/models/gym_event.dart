import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';

/// A gym event members can RSVP to. Public to any signed-in member.
class GymEvent {
  const GymEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.venue,
    this.imageUrl,
    this.rsvpCount = 0,
    this.hasRsvped = false,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startsAt;
  final String venue;
  final String? imageUrl;
  final int rsvpCount;

  /// Filled in per member by the repository, not stored on the event.
  final bool hasRsvped;

  bool get isPast => startsAt.isBefore(DateTime.now());

  factory GymEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return GymEvent(
      id: doc.id,
      title: Val.toText(data['title'], fallback: 'Event'),
      description: Val.toText(data['description']),
      startsAt: Val.toDate(data['startsAt']),
      venue: Val.toText(data['venue']),
      imageUrl: Val.toNullableText(data['imageUrl']),
      rsvpCount: Val.toInt(data['rsvpCount']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'title': title,
    'description': description,
    'startsAt': Timestamp.fromDate(startsAt),
    'venue': venue,
    'imageUrl': imageUrl,
  };

  GymEvent copyWith({bool? hasRsvped, int? rsvpCount}) => GymEvent(
    id: id,
    title: title,
    description: description,
    startsAt: startsAt,
    venue: venue,
    imageUrl: imageUrl,
    rsvpCount: rsvpCount ?? this.rsvpCount,
    hasRsvped: hasRsvped ?? this.hasRsvped,
  );
}

/// One document per member per event. The id is `${eventId}_${memberId}` so
/// the uniqueness is structural rather than enforced by a query.
class EventRsvp {
  const EventRsvp({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String memberId;
  final DateTime createdAt;

  static String idFor(String eventId, String memberId) =>
      '${eventId}_$memberId';

  factory EventRsvp.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return EventRsvp(
      id: doc.id,
      eventId: Val.toText(data['eventId']),
      memberId: Val.toText(data['memberId']),
      createdAt: Val.toDate(data[BaseFields.createdAt]),
    );
  }

  Map<String, Object?> toFirestore() => {
    'eventId': eventId,
    'memberId': memberId,
  };
}
