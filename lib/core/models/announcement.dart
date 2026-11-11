import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// A broadcast the gym sent.
///
/// Every push is mirrored into this collection by the `sendAnnouncement`
/// function, so a notification the member swiped away is still readable
/// in the app. Written with the Admin SDK; read-only from a client.
class Announcement {
  const Announcement({
    required this.base,
    required this.title,
    this.body = '',
    this.audience = 'all',
    this.sentAt,
    this.sentBy,
  });

  factory Announcement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Announcement(
      base: BaseFields.fromMap(snapshot.id, data),
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      audience: (data['audience'] as String?) ?? 'all',
      sentAt: readTimestamp(data['sentAt']),
      sentBy: data['sentBy'] as String?,
    );
  }

  final BaseFields base;
  final String title;
  final String body;
  final String audience;
  final DateTime? sentAt;
  final String? sentBy;

  String get id => base.id;
}
