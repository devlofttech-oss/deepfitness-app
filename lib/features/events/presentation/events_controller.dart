import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/events/data/event_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Upcoming events. One page; the list asks for more as it is scrolled.
final upcomingEventsProvider =
    AsyncNotifierProvider<UpcomingEventsController, List<Event>>(
      UpcomingEventsController.new,
    );

class UpcomingEventsController extends AsyncNotifier<List<Event>> {
  Page<Event>? _lastPage;

  @override
  Future<List<Event>> build() async {
    final page = await ref.watch(eventRepositoryProvider).upcoming();
    _lastPage = page;
    return page.items;
  }

  bool get hasMore => _lastPage?.hasMore ?? false;

  /// Appends the next page. Never a full collection read.
  Future<void> loadMore() async {
    final cursor = _lastPage;
    if (cursor == null || !cursor.hasMore || state.isLoading) return;

    final current = state.value ?? const <Event>[];
    final next = await ref
        .read(eventRepositoryProvider)
        .upcoming(startAfter: cursor.lastDocument);

    _lastPage = next;
    state = AsyncData([...current, ...next.items]);
  }
}

/// The events this member has said they are coming to.
final myRsvpsProvider = StreamProvider<Set<String>>((ref) {
  final memberId = ref.watch(authControllerProvider).value?.member?.id;
  if (memberId == null) return Stream.value(const {});
  return ref.watch(eventRepositoryProvider).watchMyRsvps(memberId);
});

final rsvpControllerProvider =
    AsyncNotifierProvider<RsvpController, void>(RsvpController.new);

class RsvpController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Toggles the member's RSVP for one event.
  Future<void> toggle({required String eventId, required bool going}) async {
    final memberId = ref.read(authControllerProvider).value?.member?.id;
    if (memberId == null) return;

    final repository = ref.read(eventRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (going) {
        await repository.cancelRsvp(eventId: eventId, memberId: memberId);
      } else {
        await repository.rsvp(eventId: eventId, memberId: memberId);
      }
    });
  }
}
