import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// A scheduled run of a class, with a capacity and a waitlist.
class ClassSession {
  const ClassSession({
    required this.base,
    required this.classId,
    this.instructor = '',
    this.startsAt,
    this.capacity = 0,
    this.bookedCount = 0,
    this.waitlistCount = 0,
  });

  factory ClassSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ClassSession(
      base: BaseFields.fromMap(snapshot.id, data),
      classId: (data['classId'] as String?) ?? '',
      instructor: (data['instructor'] as String?) ?? '',
      startsAt: readTimestamp(data['startsAt']),
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      bookedCount: (data['bookedCount'] as num?)?.toInt() ?? 0,
      waitlistCount: (data['waitlistCount'] as num?)?.toInt() ?? 0,
    );
  }

  final BaseFields base;
  final String classId;
  final String instructor;
  final DateTime? startsAt;
  final int capacity;
  final int bookedCount;
  final int waitlistCount;

  String get id => base.id;

  bool get isFull => bookedCount >= capacity;

  int get placesLeft => (capacity - bookedCount).clamp(0, capacity);
}
