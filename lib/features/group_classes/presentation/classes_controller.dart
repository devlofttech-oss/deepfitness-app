import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/group_classes/data/booking_repository.dart';
import 'package:deepfitness/features/group_classes/data/group_class_repository.dart';
import 'package:deepfitness/features/group_classes/domain/booking_decision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classesProvider =
    AsyncNotifierProvider<ClassesController, List<GroupClass>>(
      ClassesController.new,
    );

class ClassesController extends AsyncNotifier<List<GroupClass>> {
  Page<GroupClass>? _lastPage;

  @override
  Future<List<GroupClass>> build() async {
    final page = await ref.watch(groupClassRepositoryProvider).list();
    _lastPage = page;
    return page.items;
  }

  Future<void> loadMore() async {
    final cursor = _lastPage;
    if (cursor == null || !cursor.hasMore || state.isLoading) return;

    final current = state.value ?? const <GroupClass>[];
    final next = await ref
        .read(groupClassRepositoryProvider)
        .list(startAfter: cursor.lastDocument);

    _lastPage = next;
    state = AsyncData([...current, ...next.items]);
  }
}

/// One class by id, so the detail screen works from a deep link.
final groupClassProvider = FutureProvider.family<GroupClass?, String>(
  (ref, id) => ref.watch(groupClassRepositoryProvider).find(id),
);

/// Upcoming sessions for one class.
final classSessionsProvider =
    StreamProvider.family<List<ClassSession>, String>((ref, classId) {
      return ref.watch(bookingRepositoryProvider).watchSessions(classId);
    });

/// The whole upcoming timetable, for the booking tab.
final upcomingSessionsProvider = StreamProvider<List<ClassSession>>(
  (ref) => ref.watch(bookingRepositoryProvider).watchUpcomingSessions(),
);

/// The day the booking tab is showing. Null means every upcoming day.
final selectedSessionDayProvider = NotifierProvider<SelectedDay, DateTime?>(
  SelectedDay.new,
);

class SelectedDay extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}

/// The member's active bookings, keyed by session id.
final myBookingsProvider = StreamProvider<Map<String, Booking>>((ref) {
  final memberId = ref.watch(authControllerProvider).value?.member?.id;
  if (memberId == null) return Stream.value(const {});
  return ref.watch(bookingRepositoryProvider).watchMyBookings(memberId);
});

final bookingControllerProvider =
    AsyncNotifierProvider<BookingController, void>(BookingController.new);

class BookingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Books a place. Returns the decision so the caller can tell the member
  /// whether they got in or joined the queue, or null if it failed.
  Future<BookingDecision?> book(String sessionId) async {
    final memberId = ref.read(authControllerProvider).value?.member?.id;
    if (memberId == null) return null;

    state = const AsyncLoading();
    try {
      final decision = await ref
          .read(bookingRepositoryProvider)
          .book(sessionId: sessionId, memberId: memberId);
      state = const AsyncData(null);
      return decision;
    } on RepositoryFailure catch (failure, stackTrace) {
      state = AsyncError(failure, stackTrace);
      return null;
    }
  }

  Future<bool> cancel(String sessionId) async {
    final memberId = ref.read(authControllerProvider).value?.member?.id;
    if (memberId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bookingRepositoryProvider)
          .cancel(sessionId: sessionId, memberId: memberId),
    );
    return !state.hasError;
  }
}
