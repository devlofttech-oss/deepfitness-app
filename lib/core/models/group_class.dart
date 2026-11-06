import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';

/// Where a class video is hosted. The video itself is never uploaded — only
/// the provider and id are stored, and the app builds the embed URL.
enum VideoProvider {
  youtube,
  vimeo;

  static VideoProvider fromName(Object? value) {
    final name = value?.toString().toLowerCase();
    return VideoProvider.values.firstWhere(
      (provider) => provider.name == name,
      orElse: () => VideoProvider.youtube,
    );
  }

  /// Built here rather than stored, so a provider URL change is a one-line fix.
  String embedUrl(String videoId) {
    switch (this) {
      case VideoProvider.youtube:
        return 'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0';
      case VideoProvider.vimeo:
        return 'https://player.vimeo.com/video/$videoId';
    }
  }

  String watchUrl(String videoId) {
    switch (this) {
      case VideoProvider.youtube:
        return 'https://www.youtube.com/watch?v=$videoId';
      case VideoProvider.vimeo:
        return 'https://vimeo.com/$videoId';
    }
  }
}

/// An on-demand class video.
class GroupClass {
  const GroupClass({
    required this.id,
    required this.title,
    required this.description,
    required this.videoProvider,
    required this.videoId,
    required this.durationMins,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String description;
  final VideoProvider videoProvider;
  final String videoId;
  final int durationMins;
  final String? thumbnailUrl;

  String get embedUrl => videoProvider.embedUrl(videoId);
  String get watchUrl => videoProvider.watchUrl(videoId);

  factory GroupClass.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return GroupClass(
      id: doc.id,
      title: Val.toText(data['title'], fallback: 'Class'),
      description: Val.toText(data['description']),
      videoProvider: VideoProvider.fromName(data['videoProvider']),
      videoId: Val.toText(data['videoId']),
      durationMins: Val.toInt(data['durationMins']),
      thumbnailUrl: Val.toNullableText(data['thumbnailUrl']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'title': title,
    'description': description,
    'videoProvider': videoProvider.name,
    'videoId': videoId,
    'durationMins': durationMins,
    'thumbnailUrl': thumbnailUrl,
  };
}

/// A scheduled run of a class, with the counters the booking transaction
/// reads and writes.
class ClassSession {
  const ClassSession({
    required this.id,
    required this.classId,
    required this.classTitle,
    required this.instructor,
    required this.startsAt,
    required this.capacity,
    required this.bookedCount,
    required this.waitlistCount,
    this.myBooking,
  });

  final String id;
  final String classId;
  final String classTitle;
  final String instructor;
  final DateTime startsAt;
  final int capacity;
  final int bookedCount;
  final int waitlistCount;

  /// Filled in per member by the repository.
  final Booking? myBooking;

  bool get isFull => bookedCount >= capacity;
  int get placesLeft => (capacity - bookedCount).clamp(0, capacity);
  bool get isPast => startsAt.isBefore(DateTime.now());

  factory ClassSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ClassSession(
      id: doc.id,
      classId: Val.toText(data['classId']),
      classTitle: Val.toText(data['classTitle'], fallback: 'Class'),
      instructor: Val.toText(data['instructor']),
      startsAt: Val.toDate(data['startsAt']),
      capacity: Val.toInt(data['capacity']),
      bookedCount: Val.toInt(data['bookedCount']),
      waitlistCount: Val.toInt(data['waitlistCount']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'classId': classId,
    'classTitle': classTitle,
    'instructor': instructor,
    'startsAt': Timestamp.fromDate(startsAt),
    'capacity': capacity,
    'bookedCount': bookedCount,
    'waitlistCount': waitlistCount,
  };

  ClassSession copyWith({Booking? myBooking, bool clearBooking = false}) {
    return ClassSession(
      id: id,
      classId: classId,
      classTitle: classTitle,
      instructor: instructor,
      startsAt: startsAt,
      capacity: capacity,
      bookedCount: bookedCount,
      waitlistCount: waitlistCount,
      myBooking: clearBooking ? null : (myBooking ?? this.myBooking),
    );
  }
}

enum BookingStatus {
  booked,
  waitlisted,
  cancelled;

  static BookingStatus fromName(Object? value) {
    final name = value?.toString();
    return BookingStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => BookingStatus.cancelled,
    );
  }

  bool get holdsAPlace => this == BookingStatus.booked;
  bool get isActive => this != BookingStatus.cancelled;
}

/// A member's place in a session. Always written inside a transaction
/// alongside the session counters, so the last place cannot be oversold.
class Booking {
  const Booking({
    required this.id,
    required this.sessionId,
    required this.memberId,
    required this.status,
    required this.position,
    required this.createdAt,
    this.memberName,
  });

  final String id;
  final String sessionId;
  final String memberId;
  final BookingStatus status;

  /// Place in the waitlist, 1-based. Zero for a confirmed booking.
  final int position;
  final DateTime createdAt;
  final String? memberName;

  static String idFor(String sessionId, String memberId) =>
      '${sessionId}_$memberId';

  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Booking(
      id: doc.id,
      sessionId: Val.toText(data['sessionId']),
      memberId: Val.toText(data['memberId']),
      status: BookingStatus.fromName(data['status']),
      position: Val.toInt(data['position']),
      createdAt: Val.toDate(data[BaseFields.createdAt]),
      memberName: Val.toNullableText(data['memberName']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'sessionId': sessionId,
    'memberId': memberId,
    'status': status.name,
    'position': position,
    'memberName': memberName,
  };
}
