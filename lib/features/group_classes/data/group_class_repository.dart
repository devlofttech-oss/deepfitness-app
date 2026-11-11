import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupClassRepositoryProvider = Provider<GroupClassRepository>(
  (ref) => GroupClassRepository(ref.watch(firestoreProvider)),
);

/// The on-demand class library.
class GroupClassRepository extends BaseRepository {
  const GroupClassRepository(super.firestore);

  /// One class, for a deep link into the detail screen where the list
  /// has not been loaded.
  Future<GroupClass?> find(String id) {
    return guard(() async {
      final snapshot = await firestore
          .collection(Collections.groupClasses)
          .doc(id)
          .get();
      if (!snapshot.exists) return null;
      final groupClass = GroupClass.fromFirestore(snapshot, null);
      return groupClass.base.isDeleted ? null : groupClass;
    });
  }

  Future<Page<GroupClass>> list({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return paginate<GroupClass>(
      notDeleted(
        firestore.collection(Collections.groupClasses),
      ).orderBy('title'),
      map: (doc) => GroupClass.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }
}
