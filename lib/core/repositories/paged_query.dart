import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';

/// One page of documents plus the cursor needed to ask for the next one.
///
/// List screens use this instead of reading a whole collection — the guide is
/// explicit that a full-collection read is never acceptable.
class Page<T> {
  const Page({required this.items, this.cursor, required this.hasMore});

  const Page.empty() : items = const [], cursor = null, hasMore = false;

  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

const int defaultPageSize = 20;

/// Applies the soft-delete filter, the page size and the cursor to [query],
/// then maps the result with [fromDoc].
///
/// [includeDeleted] exists for the admin dashboard, which needs to see and
/// restore soft-deleted rows. Member-facing calls never pass it.
Future<Page<T>> fetchPage<T>({
  required Query<Map<String, dynamic>> query,
  required T Function(DocumentSnapshot<Map<String, dynamic>> doc) fromDoc,
  DocumentSnapshot<Map<String, dynamic>>? startAfter,
  int limit = defaultPageSize,
  bool includeDeleted = false,
}) async {
  var paged = query;
  if (!includeDeleted) {
    paged = paged.where(BaseFields.deletedAt, isNull: true);
  }
  if (startAfter != null) {
    paged = paged.startAfterDocument(startAfter);
  }

  // One extra document tells us whether a further page exists without a
  // second round trip.
  final snapshot = await paged.limit(limit + 1).get();
  final docs = snapshot.docs;
  final hasMore = docs.length > limit;
  final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

  return Page<T>(
    items: pageDocs.map(fromDoc).toList(),
    cursor: pageDocs.isEmpty ? null : pageDocs.last,
    hasMore: hasMore,
  );
}

/// Reads every page of [query] up to [maxDocuments].
///
/// For the handful of places that genuinely need a whole (small, bounded) set
/// — the exercise library on the plan builder, for instance. The cap is the
/// point: it fails loudly rather than quietly reading ten thousand documents.
Future<List<T>> fetchAllPaged<T>({
  required Query<Map<String, dynamic>> query,
  required T Function(DocumentSnapshot<Map<String, dynamic>> doc) fromDoc,
  int pageSize = 200,
  int maxDocuments = 2000,
}) async {
  final items = <T>[];
  DocumentSnapshot<Map<String, dynamic>>? cursor;

  while (items.length < maxDocuments) {
    final page = await fetchPage<T>(
      query: query,
      fromDoc: fromDoc,
      startAfter: cursor,
      limit: pageSize,
    );
    items.addAll(page.items);
    if (!page.hasMore || page.cursor == null) break;
    cursor = page.cursor;
  }

  return items;
}

/// Firestore's `whereIn` takes at most 30 values, so callers that filter by a
/// list of ids have to split the list and merge the results.
Iterable<List<T>> chunked<T>(List<T> values, [int size = 30]) sync* {
  for (var i = 0; i < values.length; i += size) {
    yield values.sublist(i, i + size > values.length ? values.length : i + size);
  }
}
