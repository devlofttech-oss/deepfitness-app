/// The window a report covers.
enum ReportRangeKind { week, month, custom }

/// A half-open window `[start, end)` over `completedAt`.
///
/// Half-open so a log written at midnight belongs to exactly one day and
/// is never counted in two adjacent ranges.
class ReportRange {
  const ReportRange({
    required this.kind,
    required this.start,
    required this.end,
  });

  /// The last seven days, ending at the close of today.
  factory ReportRange.week([DateTime? now]) {
    final today = startOfDay(now ?? DateTime.now());
    return ReportRange(
      kind: ReportRangeKind.week,
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    );
  }

  /// The last thirty days, ending at the close of today.
  factory ReportRange.month([DateTime? now]) {
    final today = startOfDay(now ?? DateTime.now());
    return ReportRange(
      kind: ReportRangeKind.month,
      start: today.subtract(const Duration(days: 29)),
      end: today.add(const Duration(days: 1)),
    );
  }

  /// A window the member picked. Both ends are snapped to whole days so
  /// the chart has a tick per day and the end date is included.
  factory ReportRange.custom({required DateTime from, required DateTime to}) {
    final a = startOfDay(from);
    final b = startOfDay(to);
    final ordered = a.isAfter(b) ? [b, a] : [a, b];
    return ReportRange(
      kind: ReportRangeKind.custom,
      start: ordered.first,
      end: ordered.last.add(const Duration(days: 1)),
    );
  }

  final ReportRangeKind kind;
  final DateTime start;
  final DateTime end;

  /// Whole days covered, at least one.
  int get days => end.difference(start).inDays.clamp(1, 1 << 31);

  String get label => switch (kind) {
    ReportRangeKind.week => 'Last 7 days',
    ReportRangeKind.month => 'Last 30 days',
    ReportRangeKind.custom =>
      '${_date(start)} to ${_date(end.subtract(const Duration(days: 1)))}',
  };

  static String _date(DateTime value) => '${value.day}/${value.month}';
}

/// Midnight at the start of the day [value] falls in, local time.
///
/// Reports are read by a member looking at their own week, so the day
/// boundary is theirs, not UTC's.
DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
