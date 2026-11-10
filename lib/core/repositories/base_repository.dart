import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One page of a list query, with the cursor needed to ask for the next.
class Page<T> {
  const Page({required this.items, this.lastDocument, required this.hasMore});

  const Page.empty() : items = const [], lastDocument = null, hasMore = false;

  final List<T> items;

  /// Passed back as `startAfter` to fetch the following page.
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  final bool hasMore;
}

/// Shared plumbing for every repository: error mapping, the soft-delete
/// filter and cursor pagination. No widget or provider calls Firestore
/// directly, so these three behaviours are defined in exactly one place.
abstract class BaseRepository {
  const BaseRepository(this.firestore);

  final FirebaseFirestore firestore;

  /// Runs a Firestore call and turns any Firebase error into a
  /// [RepositoryFailure], so callers never see a raw exception.
  Future<T> guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error) {
      throw RepositoryFailure.fromFirestore(error);
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  /// Applies the soft-delete filter every list query needs.
  ///
  /// Documents written before `deletedAt` existed do not hold the field at
  /// all, so the filter is `isNull` rather than an equality on null, which
  /// Firestore would not match against a missing field.
  Query<Map<String, dynamic>> notDeleted(Query<Map<String, dynamic>> query) {
    return query.where('deletedAt', isNull: true);
  }

  /// Reads one page of a query, never the whole collection.
  ///
  /// [limit] is requested plus one, so whether a further page exists is known
  /// without a second round trip; the extra document is dropped before the
  /// page is returned.
  Future<Page<T>> paginate<T>(
    Query<Map<String, dynamic>> query, {
    required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) map,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return guard(() async {
      var paged = query.limit(limit + 1);
      if (startAfter != null) {
        paged = paged.startAfterDocument(startAfter);
      }

      final snapshot = await paged.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final visible = hasMore ? docs.sublist(0, limit) : docs;

      return Page<T>(
        items: visible.map(map).toList(growable: false),
        lastDocument: visible.isEmpty ? null : visible.last,
        hasMore: hasMore,
      );
    });
  }
}

/// The collection names, in one place, so a typo is a compile error rather
/// than an empty list at runtime.
abstract final class Collections {
  static const members = 'members';
  static const exercises = 'exercises';
  static const workoutPlans = 'workout_plans';
  static const assignedPlans = 'assigned_plans';
  static const completionLogs = 'completion_logs';
  static const events = 'events';
  static const eventRsvps = 'event_rsvps';
  static const groupClasses = 'group_classes';
  static const classSessions = 'class_sessions';
  static const bookings = 'bookings';
  static const announcements = 'announcements';
}
