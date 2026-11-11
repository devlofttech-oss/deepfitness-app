import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => MemberRepository(ref.watch(firestoreProvider)),
);

/// Reads and writes the `members` collection, keyed by Firebase UID.
class MemberRepository extends BaseRepository {
  const MemberRepository(super.firestore);

  CollectionReference<Member> get _collection => firestore
      .collection(Collections.members)
      .withConverter<Member>(
        fromFirestore: Member.fromFirestore,
        toFirestore: (member, _) => member.toProfileUpdate(),
      );

  /// The member document, or null when the profile has not been created yet.
  ///
  /// A null here is what sends a signed-in user to onboarding rather than
  /// to the home screen.
  Future<Member?> find(String uid) {
    return guard(() async {
      final snapshot = await _collection.doc(uid).get();
      final member = snapshot.data();
      if (member == null || member.base.isDeleted) return null;
      return member;
    });
  }

  /// Watches the member document, so a membership lapsing or being renewed
  /// by staff reaches the app without a restart.
  Stream<Member?> watch(String uid) {
    return _collection.doc(uid).snapshots().map((snapshot) {
      final member = snapshot.data();
      if (member == null || member.base.isDeleted) return null;
      return member;
    });
  }

  /// Creates the member document on first sign-in.
  ///
  /// `onMemberCreate` also writes this document from the auth trigger. Both
  /// paths merge rather than overwrite, and neither sets `membershipStatus`
  /// or `expiryDate`, which only staff may write.
  Future<void> createProfile({
    required String uid,
    required String name,
    String? phone,
    String? email,
  }) {
    return guard(() async {
      await firestore.collection(Collections.members).doc(uid).set({
        'name': name.trim(),
        'phone': ?phone,
        'email': ?email,
        'joinedAt': FieldValue.serverTimestamp(),
        ...BaseFields.onCreate(createdBy: uid),
      }, SetOptions(merge: true));
    });
  }

  /// Saves the fields a member may change about themselves.
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? phone,
    String? email,
    String? photoUrl,
  }) {
    return guard(() async {
      await firestore.collection(Collections.members).doc(uid).update({
        'name': name.trim(),
        'phone': ?phone,
        'email': ?email,
        'photoUrl': ?photoUrl,
        ...BaseFields.onUpdate(),
      });
    });
  }
}
