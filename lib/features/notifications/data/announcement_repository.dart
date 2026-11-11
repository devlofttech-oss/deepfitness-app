import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(ref.watch(firestoreProvider)),
);

/// The announcements a member can see.
class AnnouncementRepository extends BaseRepository {
  const AnnouncementRepository(super.firestore);

  /// Announcements for this member, newest first.
  ///
  /// `audience` is matched against 'all' and 'members' together, because
  /// a broadcast sent to everyone and one sent to the member segment
  /// should both appear in the same list.
  Future<Page<Announcement>> list({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    List<String> audiences = const ['all', 'members'],
  }) {
    return paginate<Announcement>(
      firestore
          .collection(Collections.announcements)
          .where('audience', whereIn: audiences)
          .orderBy('sentAt', descending: true),
      map: (doc) => Announcement.fromFirestore(doc, null),
      limit: limit,
      startAfter: startAfter,
    );
  }
}
