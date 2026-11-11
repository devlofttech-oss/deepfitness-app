import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/features/notifications/data/announcement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final announcementsProvider =
    AsyncNotifierProvider<AnnouncementsController, List<Announcement>>(
      AnnouncementsController.new,
    );

class AnnouncementsController extends AsyncNotifier<List<Announcement>> {
  Page<Announcement>? _lastPage;

  @override
  Future<List<Announcement>> build() async {
    final page = await ref.watch(announcementRepositoryProvider).list();
    _lastPage = page;
    return page.items;
  }

  Future<void> loadMore() async {
    final cursor = _lastPage;
    if (cursor == null || !cursor.hasMore || state.isLoading) return;

    final current = state.value ?? const <Announcement>[];
    final next = await ref
        .read(announcementRepositoryProvider)
        .list(startAfter: cursor.lastDocument);

    _lastPage = next;
    state = AsyncData([...current, ...next.items]);
  }
}
