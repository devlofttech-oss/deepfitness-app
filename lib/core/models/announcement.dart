import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';

/// Who a push went to.
enum AnnouncementAudience {
  all,
  members,
  trainers;

  static AnnouncementAudience fromName(Object? value) {
    final name = value?.toString();
    return AnnouncementAudience.values.firstWhere(
      (audience) => audience.name == name,
      orElse: () => AnnouncementAudience.all,
    );
  }

  /// The FCM topic the fan-out publishes to.
  String get topic {
    switch (this) {
      case AnnouncementAudience.all:
        return 'all';
      case AnnouncementAudience.members:
        return 'members';
      case AnnouncementAudience.trainers:
        return 'trainers';
    }
  }
}

/// A mirror of every push that was sent.
///
/// The push itself is transient — a member who swipes the notification away
/// would otherwise have no way back to it, so the in-app list reads this.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.sentAt,
    this.sentBy,
    this.deepLink,
  });

  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final DateTime sentAt;
  final String? sentBy;

  /// Optional in-app route the notification opens, e.g. `/events`.
  final String? deepLink;

  factory Announcement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Announcement(
      id: doc.id,
      title: Val.toText(data['title'], fallback: 'Deep Fitness'),
      body: Val.toText(data['body']),
      audience: AnnouncementAudience.fromName(data['audience']),
      sentAt: Val.toDate(data['sentAt'] ?? data[BaseFields.createdAt]),
      sentBy: Val.toNullableText(data['sentBy']),
      deepLink: Val.toNullableText(data['deepLink']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'title': title,
    'body': body,
    'audience': audience.name,
    'sentBy': sentBy,
    'deepLink': deepLink,
    'sentAt': FieldValue.serverTimestamp(),
  };
}
