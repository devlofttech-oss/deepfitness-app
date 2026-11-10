import 'package:cloud_firestore/cloud_firestore.dart';

/// Fields every document in the project carries.
///
/// Timestamps are always written with [FieldValue.serverTimestamp] so the
/// device clock can never put a document out of order, and deletion is a
/// `deletedAt` stamp rather than a removal.
class BaseFields {
  const BaseFields({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.deletedAt,
  });

  /// Reads the base fields from a document, defaulting every one of them.
  ///
  /// Documents written by older builds of the app may predate any of these,
  /// so a missing field reads as null instead of throwing.
  factory BaseFields.fromMap(String id, Map<String, dynamic> data) {
    return BaseFields(
      id: id,
      createdAt: readTimestamp(data['createdAt']),
      updatedAt: readTimestamp(data['updatedAt']),
      createdBy: data['createdBy'] as String?,
      deletedAt: readTimestamp(data['deletedAt']),
    );
  }

  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  /// The server-stamped fields for a document being created.
  static Map<String, Object?> onCreate({String? createdBy}) => {
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    if (createdBy != null) 'createdBy': createdBy,
    'deletedAt': null,
  };

  /// The server-stamped field for a document being updated.
  static Map<String, Object?> onUpdate() => {
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// The soft delete: the document stays, the queries stop returning it.
  static Map<String, Object?> onDelete() => {
    'deletedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Reads a Firestore value that should be a time, whatever shape it arrived in.
///
/// A field written moments ago can still be a pending server timestamp, and
/// older documents may hold a millisecond count, so neither case throws.
DateTime? readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Reads a list field, defaulting to empty rather than throwing on a document
/// written before the field existed.
List<String> readStringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList(growable: false);
  }
  return const [];
}
