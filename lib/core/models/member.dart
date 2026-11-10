import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// Whether a membership is currently usable.
///
/// A lapsed membership is a state on the document, never a sign-out: the
/// member keeps read access to their own history and sees a renewal screen.
enum MembershipStatus {
  active,
  lapsed,
  suspended;

  static MembershipStatus fromName(Object? value) {
    return MembershipStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MembershipStatus.active,
    );
  }
}

/// The role a signed-in user holds.
///
/// This mirrors the `role` custom claim on the Firebase token. It is set by a
/// Cloud Function and is never a field the client can write.
enum UserRole {
  member,
  trainer,
  admin;

  static UserRole fromClaim(Object? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.member,
    );
  }

  bool get isStaff => this == UserRole.trainer || this == UserRole.admin;
}

/// A gym member. The document id is the Firebase UID.
class Member {
  const Member({
    required this.base,
    required this.name,
    required this.membershipStatus,
    this.phone,
    this.email,
    this.photoUrl,
    this.joinedAt,
    this.expiryDate,
    this.fcmTokens = const [],
  });

  /// Builds a member from a Firestore document.
  ///
  /// Every field defaults, because the app is already live and documents
  /// written by an older build will be missing whatever was added since.
  factory Member.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Member(
      base: BaseFields.fromMap(snapshot.id, data),
      name: (data['name'] as String?) ?? '',
      membershipStatus: MembershipStatus.fromName(data['membershipStatus']),
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      joinedAt: readTimestamp(data['joinedAt']),
      expiryDate: readTimestamp(data['expiryDate']),
      fcmTokens: readStringList(data['fcmTokens']),
    );
  }

  final BaseFields base;
  final String name;
  final MembershipStatus membershipStatus;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final DateTime? joinedAt;
  final DateTime? expiryDate;
  final List<String> fcmTokens;

  String get id => base.id;

  /// True once the expiry date has passed, whatever the stored status says.
  ///
  /// The status is maintained by a scheduled function, so between the expiry
  /// moment and the next run the date is the more truthful of the two.
  bool get isLapsed {
    if (membershipStatus != MembershipStatus.active) return true;
    final expiry = expiryDate;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  /// The fields a member is allowed to change about themselves.
  ///
  /// Deliberately narrow: `membershipStatus`, `expiryDate` and the base
  /// audit fields are staff-owned and the security rules reject them here.
  Map<String, Object?> toProfileUpdate() => {
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    ...BaseFields.onUpdate(),
  };

  Member copyWith({
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    MembershipStatus? membershipStatus,
    DateTime? expiryDate,
    List<String>? fcmTokens,
  }) {
    return Member(
      base: base,
      name: name ?? this.name,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
