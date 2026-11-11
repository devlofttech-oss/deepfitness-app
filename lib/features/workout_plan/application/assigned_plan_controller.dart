import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/workout_plan/data/assigned_plan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The member's current plan, watched so staff assigning a new one or
/// another device advancing the unlock shows up without a restart.
final currentPlanProvider = StreamProvider<AssignedPlan?>((ref) {
  final memberId = ref.watch(authControllerProvider).value?.member?.id;
  if (memberId == null) return Stream.value(null);
  return ref.watch(assignedPlanRepositoryProvider).watchCurrent(memberId);
});

/// Every plan the member has been assigned, newest first.
final planHistoryProvider = FutureProvider<List<AssignedPlan>>((ref) async {
  final memberId = ref.watch(authControllerProvider).value?.member?.id;
  if (memberId == null) return const [];
  final page = await ref
      .watch(assignedPlanRepositoryProvider)
      .history(memberId);
  return page.items;
});

final planProgressControllerProvider =
    AsyncNotifierProvider<PlanProgressController, void>(
      PlanProgressController.new,
    );

/// Records completions and skips against the current plan.
class PlanProgressController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> complete({
    required AssignedPlan plan,
    required PlanExercise exercise,
    required int setsDone,
  }) {
    return _record(
      plan: plan,
      exercise: exercise,
      setsDone: setsDone,
      skipped: false,
    );
  }

  /// Skips the current exercise. The reason is required by the document:
  /// it is what makes a skipped exercise readable in a report rather than
  /// an unexplained gap.
  Future<bool> skip({
    required AssignedPlan plan,
    required PlanExercise exercise,
    required String reason,
  }) {
    if (reason.trim().isEmpty) return Future.value(false);
    return _record(
      plan: plan,
      exercise: exercise,
      setsDone: 0,
      skipped: true,
      skipReason: reason,
    );
  }

  Future<bool> _record({
    required AssignedPlan plan,
    required PlanExercise exercise,
    required int setsDone,
    required bool skipped,
    String? skipReason,
  }) async {
    final memberId = ref.read(authControllerProvider).value?.member?.id;
    if (memberId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(assignedPlanRepositoryProvider)
          .recordOutcome(
            plan: plan,
            memberId: memberId,
            exercise: exercise,
            setsDone: setsDone,
            skipped: skipped,
            skipReason: skipReason,
          );
    });

    return !state.hasError;
  }
}
