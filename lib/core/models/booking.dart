import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

enum BookingStatus {
  booked,
  waitlisted,
  cancelled;

  static BookingStatus fromName(Object? value) {
    return BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.cancelled,
    );
  }
}

/// A member's place in a class session, or their place in the queue for
/// one. Always written inside a transaction with the session counters.
class Booking {
  const Booking({
    required this.base,
    required this.sessionId,
    required this.memberId,
    required this.status,
    this.position = 0,
  });

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Booking(
      base: BaseFields.fromMap(snapshot.id, data),
      sessionId: (data['sessionId'] as String?) ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      status: BookingStatus.fromName(data['status']),
      position: (data['position'] as num?)?.toInt() ?? 0,
    );
  }

  final BaseFields base;
  final String sessionId;
  final String memberId;
  final BookingStatus status;

  /// Place in the waitlist, 1-based. Zero for a confirmed booking.
  final int position;

  String get id => base.id;

  bool get isActive => status != BookingStatus.cancelled;

  /// One booking per member per session, made structural by deriving the
  /// id rather than leaving a duplicate for the rules to catch.
  static String idFor({
    required String sessionId,
    required String memberId,
  }) => '${sessionId}_$memberId';

  static Map<String, Object?> create({
    required String sessionId,
    required String memberId,
    required BookingStatus status,
    required int position,
  }) {
    return {
      'sessionId': sessionId,
      'memberId': memberId,
      'status': status.name,
      'position': position,
      ...BaseFields.onCreate(createdBy: memberId),
    };
  }
}
