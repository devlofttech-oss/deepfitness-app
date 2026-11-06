import 'package:cloud_firestore/cloud_firestore.dart';

/// Defensive readers for Firestore documents.
///
/// The app is already live, so documents written by older builds are missing
/// fields that newer builds read. Every one of these defaults rather than
/// throwing — a model must never blow up on a field that was added later.
class Val {
  const Val._();

  static int toInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static double toDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool toBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  static String toText(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static String? toNullableText(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Accepts a Firestore [Timestamp], an ISO-8601 string or epoch millis.
  static DateTime? toNullableDate(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }

  static DateTime toDate(Object? value, {DateTime? fallback}) {
    return toNullableDate(value) ?? fallback ?? DateTime.now();
  }

  static List<String> toTextList(Object? value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) return [value];
    return const [];
  }

  static List<Map<String, dynamic>> toMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> toMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  /// `yyyy-MM-dd` key used wherever a document is scoped to a single day.
  static String dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1));
}

/// The base fields every document carries, per the guide's conventions.
///
/// Timestamps are written with [FieldValue.serverTimestamp] so a wrong device
/// clock can never order one member's history ahead of another's.
class BaseFields {
  const BaseFields._();

  static const String id = 'id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String createdBy = 'createdBy';
  static const String deletedAt = 'deletedAt';

  static Map<String, Object?> onCreate({String? by}) => {
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    createdBy: by,
    deletedAt: null,
  };

  static Map<String, Object?> onUpdate() => {
    updatedAt: FieldValue.serverTimestamp(),
  };

  /// Soft delete. Nothing is hard-deleted through the app.
  static Map<String, Object?> onDelete() => {
    deletedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}
