import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/admin/data/admin_repository.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/models/workout_plan.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// The uid writes are attributed to, for `createdBy`.
final adminAuthorIdProvider = Provider<String>(
  (ref) => ref.watch(authControllerProvider).value?.user?.uid ?? '',
);

/// A dashboard list that holds one page and can ask for the next.
///
/// The repositories have always paged; this is what lets the screens use
/// it, so a gym with a thousand members does not pull the lot to render
/// the first screenful.
abstract class PagedAdminList<T> extends AsyncNotifier<List<T>> {
  Page<T>? _lastPage;

  /// Fetches one page, starting after [startAfter] when given.
  Future<Page<T>> fetch(
    AdminRepository repository, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });

  @override
  Future<List<T>> build() async {
    final page = await fetch(ref.watch(adminRepositoryProvider));
    _lastPage = page;
    return page.items;
  }

  bool get hasMore => _lastPage?.hasMore ?? false;

  Future<void> loadMore() async {
    final cursor = _lastPage;
    if (cursor == null || !cursor.hasMore || state.isLoading) return;

    final current = state.value ?? const [];
    final next = await fetch(
      ref.read(adminRepositoryProvider),
      startAfter: cursor.lastDocument,
    );

    _lastPage = next;
    state = AsyncData([...current, ...next.items]);
  }
}

final adminMembersProvider =
    AsyncNotifierProvider<AdminMembersList, List<Member>>(
      AdminMembersList.new,
    );

class AdminMembersList extends PagedAdminList<Member> {
  @override
  Future<Page<Member>> fetch(
    AdminRepository repository, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) => repository.members(startAfter: startAfter);
}

final adminExercisesProvider =
    AsyncNotifierProvider<AdminExercisesList, List<Exercise>>(
      AdminExercisesList.new,
    );

class AdminExercisesList extends PagedAdminList<Exercise> {
  @override
  Future<Page<Exercise>> fetch(
    AdminRepository repository, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) => repository.exercises(startAfter: startAfter);
}

final adminPlansProvider =
    AsyncNotifierProvider<AdminPlansList, List<WorkoutPlan>>(
      AdminPlansList.new,
    );

class AdminPlansList extends PagedAdminList<WorkoutPlan> {
  @override
  Future<Page<WorkoutPlan>> fetch(
    AdminRepository repository, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) => repository.plans(startAfter: startAfter);
}

final memberHistoryProvider =
    FutureProvider.family<List<CompletionLog>, String>(
      (ref, memberId) async =>
          (await ref.watch(adminRepositoryProvider).memberHistory(memberId))
              .items,
    );

final adminActionProvider =
    AsyncNotifierProvider<AdminActionController, void>(
      AdminActionController.new,
    );

/// Runs a dashboard write and refreshes whatever it changed.
///
/// One controller rather than one per screen: every action here is the
/// same shape — do the write, show the outcome, reload the list.
class AdminActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> run(
    Future<void> Function(AdminRepository repository) action, {
    List<ProviderOrFamily> refresh = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => action(ref.read(adminRepositoryProvider)),
    );

    if (state.hasError) return false;
    for (final provider in refresh) {
      ref.invalidate(provider);
    }
    return true;
  }
}
