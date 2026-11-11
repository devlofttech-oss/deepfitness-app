import 'package:deepfitness/admin/data/admin_repository.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/models/workout_plan.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The uid writes are attributed to, for `createdBy`.
final adminAuthorIdProvider = Provider<String>(
  (ref) => ref.watch(authControllerProvider).value?.user?.uid ?? '',
);

final adminMembersProvider = FutureProvider<List<Member>>(
  (ref) async => (await ref.watch(adminRepositoryProvider).members()).items,
);

final adminExercisesProvider = FutureProvider<List<Exercise>>(
  (ref) async => (await ref.watch(adminRepositoryProvider).exercises()).items,
);

final adminPlansProvider = FutureProvider<List<WorkoutPlan>>(
  (ref) async => (await ref.watch(adminRepositoryProvider).plans()).items,
);

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
