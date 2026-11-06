import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';

/// Whether a membership is currently paid up.
///
/// A lapsed membership is a state on the member document, not a sign-out: the
/// app shows a renewal screen and keeps read access to the member's own
/// history.
enum MembershipStatus {
  active,
  lapsed,
  suspended;

  static MembershipStatus fromName(Object? value) {
    final name = value?.toString();
    return MembershipStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => MembershipStatus.active,
    );
  }

  bool get canTrain => this == MembershipStatus.active;
}

/// The member document, keyed by the Firebase UID.
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.membershipStatus,
    required this.joinedAt,
    this.photoUrl,
    this.expiryDate,
    this.goal,
    this.gender,
    this.heightCm,
    this.age,
    this.trainerId,
    this.trainerName,
    this.waterGoalLiters = 0,
    this.notificationsEnabled = true,
    this.preferredUnit = 'kg',
    this.fcmTokens = const [],
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final MembershipStatus membershipStatus;
  final DateTime joinedAt;
  final String? photoUrl;
  final DateTime? expiryDate;
  final String? goal;
  final String? gender;
  final double? heightCm;
  final int? age;
  final String? trainerId;
  final String? trainerName;
  final double waterGoalLiters;
  final bool notificationsEnabled;
  final String preferredUnit;
  final List<String> fcmTokens;

  /// True once the expiry date is in the past, whatever the stored status says
  /// — the scheduled function that flips the status may not have run yet.
  bool get isLapsed {
    if (membershipStatus != MembershipStatus.active) return true;
    final expiry = expiryDate;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  int? get daysUntilExpiry {
    final expiry = expiryDate;
    if (expiry == null) return null;
    return expiry.difference(Val.startOfDay(DateTime.now())).inDays;
  }

  factory Member.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Member(
      id: doc.id,
      name: Val.toText(data['name'], fallback: 'Member'),
      email: Val.toText(data['email']),
      phone: Val.toNullableText(data['phone']),
      role: data['role'] == 'trainer' || data['role'] == 'admin'
          ? UserRole.trainer
          : UserRole.member,
      membershipStatus: MembershipStatus.fromName(data['membershipStatus']),
      joinedAt: Val.toDate(data['joinedAt'] ?? data[BaseFields.createdAt]),
      photoUrl: Val.toNullableText(data['photoUrl']),
      expiryDate: Val.toNullableDate(data['expiryDate']),
      goal: Val.toNullableText(data['goal']),
      gender: Val.toNullableText(data['gender']),
      heightCm: Val.toNullableDouble(data['heightCm']),
      age: Val.toNullableInt(data['age']),
      trainerId: Val.toNullableText(data['trainerId']),
      trainerName: Val.toNullableText(data['trainerName']),
      waterGoalLiters: Val.toDouble(data['waterGoalLiters']),
      notificationsEnabled: Val.toBool(
        data['notificationsEnabled'],
        fallback: true,
      ),
      preferredUnit: Val.toText(data['preferredUnit'], fallback: 'kg'),
      fcmTokens: Val.toTextList(data['fcmTokens']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'membershipStatus': membershipStatus.name,
    'photoUrl': photoUrl,
    'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
    'goal': goal,
    'gender': gender,
    'heightCm': heightCm,
    'age': age,
    'trainerId': trainerId,
    'trainerName': trainerName,
    'waterGoalLiters': waterGoalLiters,
    'notificationsEnabled': notificationsEnabled,
    'preferredUnit': preferredUnit,
  };

  AppUser toAppUser() => AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: joinedAt,
    phone: phone,
    avatarUrl: photoUrl,
    trainerName: trainerName,
    goal: goal,
    gender: gender,
    heightCm: heightCm,
    age: age,
  );

  MemberSummary toSummary({double currentWeight = 0}) => MemberSummary(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatarUrl: photoUrl,
    goal: goal ?? 'Fitness',
    heightCm: heightCm ?? 0,
    currentWeight: currentWeight,
    trainerName: trainerName ?? '',
  );
}
