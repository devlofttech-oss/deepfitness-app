import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/repositories/paged_query.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepository(ref.watch(appFirebaseProvider)),
);

/// The in-app mirror of every push that was sent to this member.
///
/// A notification swiped away is gone; this list is how a member gets back to
/// what it said, which is why `sendAnnouncement` mirrors every send.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final session = await ref.watch(authControllerProvider.future);
  if (!session.isAuthenticated) {
    throw const RepositoryFailure(
      FailureKind.unauthenticated,
      'You are not logged in.',
    );
  }
  return ref
      .watch(announcementsRepositoryProvider)
      .fetchForRole(session.role ?? UserRole.member);
});

class AnnouncementsRepository {
  const AnnouncementsRepository(this._firebase);

  final AppFirebase _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  /// Announcements sent to everyone, plus the ones aimed at this role.
  ///
  /// Firestore has no OR across different values on one field in a single
  /// ordered query, so the two audiences are fetched separately and merged.
  Future<List<Announcement>> fetchForRole(
    UserRole role, {
    int limit = defaultPageSize,
  }) {
    return guard(() async {
      _firebase.requireUserId();

      final audiences = <AnnouncementAudience>[
        AnnouncementAudience.all,
        role.isStaff
            ? AnnouncementAudience.trainers
            : AnnouncementAudience.members,
      ];

      final collected = <Announcement>[];
      for (final audience in audiences) {
        final page = await fetchPage<Announcement>(
          query: _db
              .collection(FirestorePaths.announcements)
              .where('audience', isEqualTo: audience.name)
              .orderBy('sentAt', descending: true),
          fromDoc: Announcement.fromFirestore,
          limit: limit,
        );
        collected.addAll(page.items);
      }

      collected.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return collected.take(limit).toList();
    }, whileDoing: 'loading your notifications');
  }
}
