import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/paged_query.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _appDataTimeout = Duration(seconds: 20);

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(ref.watch(appFirebaseProvider)),
);

final currentAuthUserIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authControllerProvider.select(
      (state) => state.maybeWhen(
        data: (session) => session.userId,
        orElse: () => null,
      ),
    ),
  );
});

final currentUserProvider = FutureProvider<AppUser>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchCurrentUser(),
  );
});

/// The plan the member is on today, with the unlock state already applied.
final workoutProvider = FutureProvider<WorkoutPlan>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchTodayWorkout(date: DateTime.now()),
  );
});

final nutritionProvider = FutureProvider<NutritionPlan>((ref) {
  final date = ref.watch(nutritionDateProvider);
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchNutritionPlan(date: date),
  );
});

final todayNutritionProvider = FutureProvider<NutritionPlan>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchNutritionPlan(),
  );
});

final nutritionDateProvider =
    NotifierProvider<NutritionDateController, DateTime>(
      NutritionDateController.new,
    );

final progressProvider = FutureProvider<MemberProgress>((ref) {
  final range = ref.watch(progressDateRangeProvider);
  return _loadForSignedInUser(
    ref,
    (repository) =>
        repository.fetchProgress(startDate: range?.start, endDate: range?.end),
  );
});

final progressDateRangeProvider =
    NotifierProvider<
      ProgressDateRangeController,
      ({DateTime start, DateTime end})?
    >(ProgressDateRangeController.new);

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  return _loadForSignedInUser(ref, (repository) => repository.fetchSettings());
});

final membersProvider = FutureProvider<List<MemberSummary>>((ref) {
  return _loadForSignedInUser(ref, (repository) => repository.fetchMembers());
});

final exerciseLibraryProvider = FutureProvider<List<Exercise>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchExerciseLibrary(),
);

final trainerStatsProvider = FutureProvider<TrainerDashboardStats>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchTrainerStats(),
  );
});

final savedWorkoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchSavedWorkoutPlans(),
  );
});

final savedDietPlansProvider = FutureProvider<List<NutritionPlan>>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchSavedDietPlans(),
  );
});

final mealTemplatesProvider = FutureProvider<List<DietMeal>>((ref) {
  return _loadForSignedInUser(
    ref,
    (repository) => repository.fetchMealTemplates(),
  );
});

Future<T> _loadForSignedInUser<T>(
  Ref ref,
  Future<T> Function(AppDataRepository repository) load,
) async {
  final session = await ref
      .watch(authControllerProvider.future)
      .timeout(
        _appDataTimeout,
        onTimeout: () => throw const RepositoryFailure(
          FailureKind.network,
          'Timed out while checking your login session.',
        ),
      );
  if (!session.isAuthenticated || session.userId == null) {
    throw const RepositoryFailure(
      FailureKind.unauthenticated,
      'You are not logged in.',
    );
  }

  final repository = ref.watch(appDataRepositoryProvider);
  return load(repository);
}

final selectedExerciseProvider =
    NotifierProvider<SelectedExerciseController, Exercise?>(
      SelectedExerciseController.new,
    );

class SelectedExerciseController extends Notifier<Exercise?> {
  @override
  Exercise? build() => null;

  void select(Exercise exercise) => state = exercise;
}

class NutritionDateController extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime date) => state = date;
}

class ProgressDateRangeController
    extends Notifier<({DateTime start, DateTime end})?> {
  @override
  ({DateTime start, DateTime end})? build() => null;

  void select(DateTime start, DateTime end) => state = (start: start, end: end);

  /// Week and month presets, as the reports module calls for.
  void selectLastWeek() {
    final now = DateTime.now();
    select(Val.startOfDay(now).subtract(const Duration(days: 6)), now);
  }

  void selectThisMonth() {
    final now = DateTime.now();
    select(DateTime(now.year, now.month, 1), now);
  }

  void clear() => state = null;
}

final exerciseLogsProvider =
    AsyncNotifierProvider<ExerciseLogsController, List<ExerciseLog>>(
      ExerciseLogsController.new,
    );

class AppDataRepository {
  const AppDataRepository(this._firebase);

  final AppFirebase _firebase;

  FirebaseFirestore get _db => _firebase.firestore;

  String get _uid => _firebase.requireUserId();

  // ------------------------------------------------------------------ profile

  Future<AppUser> fetchCurrentUser() {
    return guard(() async {
      final uid = _uid;
      final doc = await _db
          .collection(FirestorePaths.members)
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw const RepositoryFailure(
          FailureKind.notFound,
          'Your saved session no longer matches an active profile. '
          'Please sign in again.',
        );
      }

      return Member.fromFirestore(doc).toAppUser();
    }, whileDoing: 'loading your profile');
  }

  // ----------------------------------------------------------- today's plan

  /// The plan assigned for [date], or an empty placeholder when none is.
  Future<WorkoutPlan> fetchTodayWorkout({String? memberId, DateTime? date}) {
    return guard(() async {
      final userId = memberId ?? _uid;
      final dayKey = Val.dayKey(date ?? DateTime.now());

      final snapshot = await _db
          .collection(FirestorePaths.assignedPlans)
          .where('memberId', isEqualTo: userId)
          .where('scheduledDate', isEqualTo: dayKey)
          .where(BaseFields.deletedAt, isNull: true)
          .orderBy('assignedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return _emptyWorkout();

      final plan = AssignedPlan.fromFirestore(snapshot.docs.first);
      return _withProgress(plan);
    }, whileDoing: 'loading your workout');
  }

  /// Reads the in-progress drafts and finished logs for [plan] and folds the
  /// completed set counts back onto the exercises.
  Future<WorkoutPlan> _withProgress(AssignedPlan plan) async {
    final completedByOrder = <int, int>{};

    final drafts = await _db
        .collection(FirestorePaths.assignedPlans)
        .doc(plan.id)
        .collection('progress')
        .get();

    for (final doc in drafts.docs) {
      final order = int.tryParse(doc.id);
      if (order == null) continue;
      final sets = Val.toMapList(doc.data()['sets']);
      completedByOrder[order] = sets
          .where((set) => Val.toBool(set['completed'], fallback: true))
          .length;
    }

    final logs = await _db
        .collection(FirestorePaths.completionLogs)
        .where('assignedPlanId', isEqualTo: plan.id)
        .where(BaseFields.deletedAt, isNull: true)
        .get();

    for (final doc in logs.docs) {
      final log = CompletionLog.fromFirestore(doc);
      if (log.skipped) continue;
      completedByOrder[log.exerciseIndex] = log.setsDone;
    }

    return plan.toWorkoutPlan(completedSetsByOrder: completedByOrder);
  }

  Future<AssignedPlan?> _loadAssignedPlan(String planId) async {
    if (planId == 'empty') return null;
    final doc = await _db
        .collection(FirestorePaths.assignedPlans)
        .doc(planId)
        .get();
    if (!doc.exists) return null;
    return AssignedPlan.fromFirestore(doc);
  }

  // --------------------------------------------------- complete / skip / log

  /// Writes the completion log and advances the unlock, in one batch.
  ///
  /// Both halves have to land together: a log without the advance leaves the
  /// member stuck on an exercise they have finished, and an advance without a
  /// log loses the work from every report.
  Future<void> completeExercise({
    required WorkoutPlan workout,
    required Exercise exercise,
    required List<ExerciseLog> logs,
  }) {
    return guard(() async {
      final uid = _uid;
      final plan = await _loadAssignedPlan(workout.id);
      if (plan == null) {
        throw const RepositoryFailure(
          FailureKind.notFound,
          'That plan is no longer assigned to you.',
        );
      }

      final index = workout.indexOf(exercise);
      if (index < 0) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'That exercise is not part of this plan.',
        );
      }
      if (plan.isLockedAt(index)) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Finish the exercise before this one first.',
        );
      }

      final snapshot = plan.exercises[index];
      final completedSets = logs
          .where((log) => log.completed)
          .map(CompletedSet.fromLog)
          .toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      await _writeCompletion(
        uid: uid,
        plan: plan,
        index: index,
        snapshot: snapshot,
        sets: completedSets,
        skipped: false,
        skipReason: null,
      );
    }, whileDoing: 'saving your exercise');
  }

  /// Moves past an exercise without completing it.
  ///
  /// A reason is required and the index still advances, so a member can never
  /// be stuck behind an exercise they cannot do.
  Future<void> skipExercise({
    required WorkoutPlan workout,
    required Exercise exercise,
    required String reason,
  }) {
    return guard(() async {
      final uid = _uid;
      final trimmed = reason.trim();
      if (trimmed.isEmpty) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Tell your trainer why you are skipping this one.',
        );
      }

      final plan = await _loadAssignedPlan(workout.id);
      if (plan == null) {
        throw const RepositoryFailure(
          FailureKind.notFound,
          'That plan is no longer assigned to you.',
        );
      }

      final index = workout.indexOf(exercise);
      if (index < 0) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'That exercise is not part of this plan.',
        );
      }

      await _writeCompletion(
        uid: uid,
        plan: plan,
        index: index,
        snapshot: plan.exercises[index],
        sets: const [],
        skipped: true,
        skipReason: trimmed,
      );
    }, whileDoing: 'skipping that exercise');
  }

  Future<void> _writeCompletion({
    required String uid,
    required AssignedPlan plan,
    required int index,
    required AssignedExercise snapshot,
    required List<CompletedSet> sets,
    required bool skipped,
    required String? skipReason,
  }) async {
    final batch = _db.batch();

    final logRef = _db.collection(FirestorePaths.completionLogs).doc();
    final log = CompletionLog(
      id: logRef.id,
      memberId: uid,
      assignedPlanId: plan.id,
      exerciseIndex: index,
      exerciseId: snapshot.exerciseId,
      exerciseName: snapshot.name,
      muscleGroup: snapshot.muscleGroup,
      setsPlanned: snapshot.sets,
      setsDone: sets.length,
      sets: sets,
      skipped: skipped,
      skipReason: skipReason,
      completedAt: DateTime.now(),
      tracksWeight: snapshot.tracksWeight,
    );
    batch.set(logRef, {
      ...log.toFirestore(),
      ...BaseFields.onCreate(by: uid),
    });

    // Never move the index backwards: a member re-opening a finished exercise
    // must not re-lock the ones after it.
    final nextIndex = index + 1 > plan.currentIndex
        ? index + 1
        : plan.currentIndex;
    final isFinished = nextIndex >= plan.exercises.length;

    batch.update(_db.collection(FirestorePaths.assignedPlans).doc(plan.id), {
      'currentIndex': nextIndex,
      if (isFinished) 'status': AssignedPlanStatus.completed.name,
      if (isFinished) 'completedAt': FieldValue.serverTimestamp(),
      ...BaseFields.onUpdate(),
    });

    await batch.commit();
  }

  /// In-progress sets for an exercise, so a half-finished set survives the
  /// app being closed.
  Future<List<ExerciseLog>> fetchExerciseLogs(Exercise exercise) {
    return guard(() async {
      _firebase.requireConfigured();
      final ref = _progressRef(exercise);
      if (ref == null) return _defaultLogs(exercise);

      final doc = await ref.get();
      final sets = Val.toMapList(doc.data()?['sets']);
      if (sets.isEmpty) return _defaultLogs(exercise);

      final logs = sets
          .map(
            (set) => ExerciseLog(
              setNumber: Val.toInt(set['setNumber'], fallback: 1),
              weight: Val.toInt(set['weight']),
              reps: Val.toInt(set['reps']),
              completed: Val.toBool(set['completed'], fallback: true),
            ),
          )
          .toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
      return logs;
    }, whileDoing: 'loading your sets');
  }

  Future<void> saveExerciseLogs(Exercise exercise, List<ExerciseLog> logs) {
    return guard(() async {
      final uid = _uid;
      final ref = _progressRef(exercise);
      if (ref == null) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Open an assigned workout exercise before saving sets.',
        );
      }

      final unique = <int, ExerciseLog>{};
      for (final log in logs) {
        unique[log.setNumber] = log;
      }
      final sorted = unique.values.toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      await ref.set({
        'memberId': uid,
        'exerciseId': exercise.id,
        'sets': [
          for (final log in sorted)
            {
              'setNumber': log.setNumber,
              'weight': log.weight,
              'reps': log.reps,
              'completed': log.completed,
            },
        ],
        ...BaseFields.onUpdate(),
      }, SetOptions(merge: true));
    }, whileDoing: 'saving your sets');
  }

  Future<void> saveExerciseNote(Exercise exercise, String note) {
    return guard(() async {
      final uid = _uid;
      final ref = _progressRef(exercise);
      if (ref == null) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Open an assigned workout exercise before saving notes.',
        );
      }
      await ref.set({
        'memberId': uid,
        'note': note.trim(),
        ...BaseFields.onUpdate(),
      }, SetOptions(merge: true));
    }, whileDoing: 'saving your note');
  }

  Future<String> fetchExerciseNote(Exercise exercise) {
    return guard(() async {
      _firebase.requireConfigured();
      final ref = _progressRef(exercise);
      if (ref == null) return '';
      final doc = await ref.get();
      return Val.toText(doc.data()?['note']);
    }, whileDoing: 'loading your note');
  }

  /// `assigned_plans/{planId}/progress/{order}` — the draft for one exercise.
  DocumentReference<Map<String, dynamic>>? _progressRef(Exercise exercise) {
    final key = exercise.workoutExerciseId;
    if (key == null || !key.contains(':')) return null;
    final parts = key.split(':');
    if (parts.length != 2) return null;
    return _db
        .collection(FirestorePaths.assignedPlans)
        .doc(parts[0])
        .collection('progress')
        .doc(parts[1]);
  }

  /// Marks the whole plan finished. The per-exercise logs are what the reports
  /// read; this only closes the plan out.
  Future<void> completeWorkout(WorkoutPlan workout) {
    return guard(() async {
      _uid;
      if (workout.isEmpty) return;
      await _db.collection(FirestorePaths.assignedPlans).doc(workout.id).update(
        {
          'status': AssignedPlanStatus.completed.name,
          'currentIndex': workout.exercises.length,
          'completedAt': FieldValue.serverTimestamp(),
          ...BaseFields.onUpdate(),
        },
      );
    }, whileDoing: 'finishing your workout');
  }

  /// Puts a plan back to the start.
  ///
  /// The completion logs are soft-deleted rather than removed — the guide is
  /// explicit that nothing is hard-deleted through the app.
  Future<void> resetWorkoutProgress(WorkoutPlan workout) {
    return guard(() async {
      _uid;
      if (workout.isEmpty) return;

      final batch = _db.batch();
      final planRef = _db
          .collection(FirestorePaths.assignedPlans)
          .doc(workout.id);

      final logs = await _db
          .collection(FirestorePaths.completionLogs)
          .where('assignedPlanId', isEqualTo: workout.id)
          .where(BaseFields.deletedAt, isNull: true)
          .get();
      for (final doc in logs.docs) {
        batch.update(doc.reference, BaseFields.onDelete());
      }

      final drafts = await planRef.collection('progress').get();
      for (final doc in drafts.docs) {
        batch.delete(doc.reference);
      }

      batch.update(planRef, {
        'currentIndex': 0,
        'status': AssignedPlanStatus.active.name,
        'completedAt': null,
        ...BaseFields.onUpdate(),
      });

      await batch.commit();
    }, whileDoing: 'resetting your workout');
  }

  // ------------------------------------------------------------------ reports

  /// Everything on the progress screen, derived from the completion log.
  Future<MemberProgress> fetchProgress({
    String? memberId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return guard(() async {
      final userId = memberId ?? _uid;

      final measurements = await _db
          .collection(FirestorePaths.measurements)
          .where('memberId', isEqualTo: userId)
          .where(BaseFields.deletedAt, isNull: true)
          .orderBy('measuredAt', descending: true)
          .limit(2)
          .get();

      final currentWeight = measurements.docs.isEmpty
          ? 0.0
          : Val.toDouble(measurements.docs.first.data()['weight']);
      final previousWeight = measurements.docs.length > 1
          ? Val.toDouble(
              measurements.docs[1].data()['weight'],
              fallback: currentWeight,
            )
          : currentWeight;

      // One query on completedAt over the selected range, as the guide asks.
      var query = _db
          .collection(FirestorePaths.completionLogs)
          .where('memberId', isEqualTo: userId)
          .where(BaseFields.deletedAt, isNull: true);
      if (startDate != null) {
        query = query.where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(Val.startOfDay(startDate)),
        );
      }
      if (endDate != null) {
        query = query.where(
          'completedAt',
          isLessThan: Timestamp.fromDate(Val.endOfDay(endDate)),
        );
      }

      final logs = await fetchAllPaged<CompletionLog>(
        query: query.orderBy('completedAt', descending: true),
        fromDoc: CompletionLog.fromFirestore,
      );

      final done = logs.where((log) => !log.skipped).toList();

      final personalBests = <String, int>{};
      final muscleCounts = <String, int>{};
      for (final log in done) {
        final muscle = _mainMuscleGroup(log.muscleGroup);
        muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + 1;
        final best = log.topWeight;
        if (best > 0 &&
            (!personalBests.containsKey(log.exerciseName) ||
                best > personalBests[log.exerciseName]!)) {
          personalBests[log.exerciseName] = best;
        }
      }

      final sortedMuscles = muscleCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedBests = personalBests.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final plans = await _plansInRange(
        memberId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      final stats = _assignmentStats(plans, logs);
      final member = await _db
          .collection(FirestorePaths.members)
          .doc(userId)
          .get();

      return MemberProgress(
        currentWeight: currentWeight,
        weightDelta: double.parse(
          (currentWeight - previousWeight).toStringAsFixed(1),
        ),
        workoutsCompleted: plans
            .where((plan) => plan.status == AssignedPlanStatus.completed)
            .length,
        goalCompletion: await _latestPlanCompletion(userId),
        dayStreak: _dayStreak(done),
        muscleProgress: Map.fromEntries(
          sortedMuscles
              .take(6)
              .map(
                (entry) => MapEntry(entry.key, (entry.value * 7).clamp(8, 100)),
              ),
        ),
        personalBests: Map.fromEntries(sortedBests.take(6)),
        assignedExercises: stats.assigned,
        completedExercises: stats.completed,
        missedExercises: stats.missed,
        adherence: stats.adherence,
        dailyCompletions: _dailyCompletions(
          done,
          startDate: startDate,
          endDate: endDate,
        ),
        gender: Val.toNullableText(member.data()?['gender']),
      );
    }, whileDoing: 'building your report');
  }

  Future<List<AssignedPlan>> _plansInRange({
    required String memberId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    // Today is still in progress, so it does not count against adherence.
    final yesterday = Val.startOfDay(now).subtract(const Duration(days: 1));
    final effectiveStart = startDate ?? DateTime(now.year, now.month, 1);
    final effectiveEnd = endDate == null || endDate.isAfter(yesterday)
        ? yesterday
        : endDate;
    if (effectiveEnd.isBefore(effectiveStart)) return const [];

    return fetchAllPaged<AssignedPlan>(
      query: _db
          .collection(FirestorePaths.assignedPlans)
          .where('memberId', isEqualTo: memberId)
          .where(
            'scheduledDate',
            isGreaterThanOrEqualTo: Val.dayKey(effectiveStart),
          )
          .where('scheduledDate', isLessThanOrEqualTo: Val.dayKey(effectiveEnd))
          .orderBy('scheduledDate', descending: true),
      fromDoc: AssignedPlan.fromFirestore,
    );
  }

  ({int assigned, int completed, int missed, double adherence})
  _assignmentStats(List<AssignedPlan> plans, List<CompletionLog> logs) {
    final assigned = plans.fold<int>(
      0,
      (total, plan) => total + plan.exercises.length,
    );
    if (assigned == 0) {
      return (assigned: 0, completed: 0, missed: 0, adherence: 0.0);
    }

    final planIds = plans.map((plan) => plan.id).toSet();
    final completed = logs
        .where((log) => !log.skipped && planIds.contains(log.assignedPlanId))
        .map((log) => '${log.assignedPlanId}:${log.exerciseIndex}')
        .toSet()
        .length;

    final missed = (assigned - completed).clamp(0, assigned);
    return (
      assigned: assigned,
      completed: completed,
      missed: missed,
      adherence: completed / assigned,
    );
  }

  Future<double> _latestPlanCompletion(String memberId) async {
    final snapshot = await _db
        .collection(FirestorePaths.assignedPlans)
        .where('memberId', isEqualTo: memberId)
        .where(BaseFields.deletedAt, isNull: true)
        .orderBy('assignedAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 0;

    final plan = AssignedPlan.fromFirestore(snapshot.docs.first);
    if (plan.exercises.isEmpty) return 0;
    return (plan.currentIndex / plan.exercises.length).clamp(0.0, 1.0);
  }

  /// Completions per day across the range, including the empty days.
  ///
  /// The gaps matter: a chart that silently drops them would draw four
  /// scattered workouts as though they were consecutive.
  List<DayCount> _dailyCompletions(
    List<CompletionLog> logs, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = Val.startOfDay(
      startDate ?? DateTime(now.year, now.month, 1),
    );
    final end = Val.startOfDay(endDate ?? now);
    if (end.isBefore(start)) return const [];

    final counts = <DateTime, int>{};
    for (final log in logs) {
      final day = Val.startOfDay(log.completedAt);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    // A long range would draw more bars than there are pixels, so cap it.
    const maxBars = 31;
    final days = end.difference(start).inDays + 1;
    final from = days > maxBars
        ? end.subtract(const Duration(days: maxBars - 1))
        : start;

    return [
      for (
        var day = from;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      )
        DayCount(day, counts[day] ?? 0),
    ];
  }

  int _dayStreak(List<CompletionLog> logs) {
    final days = logs.map((log) => Val.startOfDay(log.completedAt)).toSet();
    if (days.isEmpty) return 0;

    var cursor = Val.startOfDay(DateTime.now());
    if (!days.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!days.contains(yesterday)) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ----------------------------------------------------------------- settings

  Future<AppSettings> fetchSettings() {
    return guard(() async {
      final doc = await _db
          .collection(FirestorePaths.members)
          .doc(_uid)
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      return AppSettings(
        notificationsEnabled: Val.toBool(
          data['notificationsEnabled'],
          fallback: true,
        ),
        preferredUnit: Val.toText(data['preferredUnit'], fallback: 'kg'),
      );
    }, whileDoing: 'loading your settings');
  }

  Future<void> updateNotificationsEnabled(bool enabled) {
    return guard(() async {
      await _db.collection(FirestorePaths.members).doc(_uid).update({
        'notificationsEnabled': enabled,
        ...BaseFields.onUpdate(),
      });
    }, whileDoing: 'saving your settings');
  }

  Future<void> updatePreferredUnit(String unit) {
    return guard(() async {
      await _db.collection(FirestorePaths.members).doc(_uid).update({
        'preferredUnit': unit,
        ...BaseFields.onUpdate(),
      });
    }, whileDoing: 'saving your settings');
  }

  // -------------------------------------------------------------- trainer side

  /// Members this trainer coaches, newest first, one page at a time.
  Future<List<MemberSummary>> fetchMembers({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final page = await fetchPage<MemberSummary>(
        query: _db
            .collection(FirestorePaths.members)
            .where('role', isEqualTo: 'member')
            .orderBy(BaseFields.createdAt, descending: true),
        fromDoc: (doc) {
          final member = Member.fromFirestore(doc);
          return member.toSummary(
            currentWeight: Val.toDouble(doc.data()?['currentWeight']),
          );
        },
        startAfter: startAfter,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading members');
  }

  Future<List<Exercise>> fetchExerciseLibrary() {
    return guard(() async {
      _firebase.requireConfigured();
      return fetchAllPaged<Exercise>(
        query: _db
            .collection(FirestorePaths.exercises)
            .orderBy('muscleGroup')
            .orderBy('name'),
        fromDoc: Exercise.fromFirestore,
      );
    }, whileDoing: 'loading the exercise library');
  }

  Future<TrainerDashboardStats> fetchTrainerStats() {
    return guard(() async {
      _firebase.requireConfigured();

      // count() keeps this a server-side aggregate rather than a full read.
      final members = await _db
          .collection(FirestorePaths.members)
          .where('role', isEqualTo: 'member')
          .where(BaseFields.deletedAt, isNull: true)
          .count()
          .get();

      final plans = await _db
          .collection(FirestorePaths.assignedPlans)
          .where('status', isEqualTo: AssignedPlanStatus.active.name)
          .where(BaseFields.deletedAt, isNull: true)
          .count()
          .get();

      return TrainerDashboardStats(
        memberCount: members.count ?? 0,
        activePlanCount: plans.count ?? 0,
      );
    }, whileDoing: 'loading your dashboard');
  }

  /// Reusable plan templates this trainer has built.
  Future<List<WorkoutPlan>> fetchSavedWorkoutPlans({int limit = 8}) {
    return guard(() async {
      final uid = _uid;
      final page = await fetchPage<WorkoutPlan>(
        query: _db
            .collection(FirestorePaths.workoutPlans)
            .where(BaseFields.createdBy, isEqualTo: uid)
            .orderBy(BaseFields.createdAt, descending: true),
        fromDoc: _workoutPlanFromTemplate,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading your saved plans');
  }

  WorkoutPlan _workoutPlanFromTemplate(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final raw = Val.toMapList(data['exercises']);
    final exercises = <Exercise>[
      for (var i = 0; i < raw.length; i++)
        AssignedExercise.fromMap(raw[i], order: i).toExercise(
          planId: doc.id,
          completedSetCount: 0,
          isLocked: false,
        ),
    ];

    return WorkoutPlan(
      id: doc.id,
      name: Val.toText(data['title'], fallback: 'Plan'),
      focus: Val.toText(data['focus'], fallback: 'Assigned Program'),
      durationMinutes: Val.toInt(data['durationMinutes']),
      estimatedCalories: Val.toInt(data['estimatedCalories']),
      level: Val.toText(data['level']),
      completionPercent: 0,
      exercises: exercises,
    );
  }

  /// Saves a reusable template and assigns it, snapshotting the exercises.
  Future<void> saveWorkoutPlan({
    required String memberId,
    required String name,
    required String focus,
    required List<Exercise> exercises,
    DateTime? scheduledFor,
  }) {
    return guard(() async {
      final uid = _uid;
      if (exercises.isEmpty) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Add at least one exercise to the plan.',
        );
      }

      final snapshots = <AssignedExercise>[
        for (var i = 0; i < exercises.length; i++)
          AssignedExercise.snapshot(exercises[i], i),
      ];
      final durationMinutes = _estimatedDurationMinutes(exercises);
      final batch = _db.batch();

      final templateRef = _db.collection(FirestorePaths.workoutPlans).doc();
      batch.set(templateRef, {
        'title': name,
        'focus': focus,
        'level': '',
        'durationMinutes': durationMinutes,
        'estimatedCalories': durationMinutes * 8,
        'exercises': snapshots.map((item) => item.toMap()).toList(),
        ...BaseFields.onCreate(by: uid),
      });

      final assignedRef = _db.collection(FirestorePaths.assignedPlans).doc();
      final plan = AssignedPlan(
        id: assignedRef.id,
        memberId: memberId,
        planId: templateRef.id,
        title: name,
        focus: focus,
        level: '',
        durationMinutes: durationMinutes,
        estimatedCalories: durationMinutes * 8,
        scheduledDate: Val.dayKey(scheduledFor ?? DateTime.now()),
        exercises: snapshots,
        currentIndex: 0,
        status: AssignedPlanStatus.active,
        assignedAt: DateTime.now(),
        assignedBy: uid,
      );
      batch.set(assignedRef, {
        ...plan.toFirestore(),
        'assignedAt': FieldValue.serverTimestamp(),
        ...BaseFields.onCreate(by: uid),
      });

      await batch.commit();
    }, whileDoing: 'saving the plan');
  }

  Future<void> createQuickWorkoutPlan(String memberId) async {
    final exercises = await fetchExerciseLibrary();
    if (exercises.isEmpty) {
      throw const RepositoryFailure(
        FailureKind.invalid,
        'Add exercises to the library first.',
      );
    }
    await saveWorkoutPlan(
      memberId: memberId,
      name: 'Quick Workout',
      focus: 'Assigned Workout',
      exercises: exercises.take(4).toList(),
    );
  }

  Future<void> addMeasurement(String memberId, double weight) {
    return guard(() async {
      final uid = _uid;
      final batch = _db.batch();

      batch.set(_db.collection(FirestorePaths.measurements).doc(), {
        'memberId': memberId,
        'weight': weight,
        'notes': 'Trainer update',
        'measuredAt': FieldValue.serverTimestamp(),
        ...BaseFields.onCreate(by: uid),
      });

      // Denormalised onto the member so the member list is one query rather
      // than one per row.
      batch.update(_db.collection(FirestorePaths.members).doc(memberId), {
        'currentWeight': weight,
        ...BaseFields.onUpdate(),
      });

      await batch.commit();
    }, whileDoing: 'saving the measurement');
  }

  /// Creates a member account. Privileged, so it goes through a callable
  /// function — the client has no business writing another user's auth record.
  Future<CreatedMemberInvite> createMember({
    required String name,
    required String? email,
    required String? phone,
    required String password,
    required String goal,
    required String gender,
    required int? age,
    required double heightCm,
    required double weight,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final callable = FirebaseFunctions.instance.httpsCallable('createMember');
      final response = await callable.call<Map<String, dynamic>>({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'goal': goal,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weight': weight,
      });

      final data = Map<String, dynamic>.from(response.data);
      final memberData = Val.toMap(data['member']);

      return CreatedMemberInvite(
        member: MemberSummary(
          id: Val.toText(memberData['id']),
          name: Val.toText(memberData['name'], fallback: name),
          email: Val.toText(memberData['email'], fallback: email ?? ''),
          phone: Val.toNullableText(memberData['phone']) ?? phone,
          goal: Val.toText(memberData['goal'], fallback: goal),
          heightCm: Val.toDouble(memberData['heightCm'], fallback: heightCm),
          currentWeight: Val.toDouble(
            memberData['weight'],
            fallback: weight,
          ),
          trainerName: Val.toText(memberData['trainerName'], fallback: 'You'),
        ),
        inviteText: Val.toText(data['inviteText']),
      );
    }, whileDoing: 'creating the member', timeout: const Duration(seconds: 45));
  }

  String workoutShareText(WorkoutPlan workout) {
    final buffer = StringBuffer()
      ..writeln(workout.name)
      ..writeln(workout.focus)
      ..write(
        '${workout.durationMinutes} min - ${workout.exercises.length} exercises',
      );
    if (workout.estimatedCalories > 0) {
      buffer.write(' - ${workout.estimatedCalories} kcal');
    }
    buffer.writeln();
    for (final exercise in workout.exercises) {
      buffer.writeln(
        '- ${exercise.name}: ${exercise.sets} sets x ${exercise.reps}, '
        'rest ${exercise.restSeconds}s',
      );
    }
    return buffer.toString().trim();
  }

  // --------------------------------------------------------------------- diet
  // Hidden in the UI, retained so the feature can be restored.

  Future<NutritionPlan> fetchNutritionPlan({String? memberId, DateTime? date}) {
    return guard(() async {
      final userId = memberId ?? _uid;
      final selected = date ?? DateTime.now();
      final dayKey = Val.dayKey(selected);

      final memberDoc = await _db
          .collection(FirestorePaths.members)
          .doc(userId)
          .get();
      final waterGoal = Val.toDouble(memberDoc.data()?['waterGoalLiters']);
      final waterLiters = await _waterForDay(userId, dayKey);

      final snapshot = await _db
          .collection(FirestorePaths.dietPlans)
          .where('memberId', isEqualTo: userId)
          .where('scheduledDate', isEqualTo: dayKey)
          .where(BaseFields.deletedAt, isNull: true)
          .orderBy(BaseFields.createdAt, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return _emptyNutrition(
          waterLiters: waterLiters,
          waterGoalLiters: waterGoal,
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final logged = await _loggedMealIds(userId, doc.id, dayKey);

      final meals = <DietMeal>[
        for (final raw in Val.toMapList(data['meals']))
          DietMeal(
            id: Val.toText(raw['id']),
            name: Val.toText(raw['name'], fallback: 'Meal'),
            time: Val.toText(raw['time']),
            description: Val.toText(raw['description']),
            calories: Val.toInt(raw['calories']),
            icon: Val.toText(raw['name']).toLowerCase(),
            logged: logged.contains(Val.toText(raw['id'])),
          ),
      ];

      final consumed = meals
          .where((meal) => meal.logged)
          .fold<int>(0, (total, meal) => total + meal.calories);
      final goal = Val.toInt(data['dailyCalories']);

      return NutritionPlan(
        calories: consumed,
        goalCalories: goal,
        protein: _macroConsumed(Val.toInt(data['proteinG']), consumed, goal),
        carbs: _macroConsumed(Val.toInt(data['carbsG']), consumed, goal),
        fats: _macroConsumed(Val.toInt(data['fatsG']), consumed, goal),
        caloriesLeft: (goal - consumed).clamp(0, goal),
        waterLiters: waterLiters,
        waterGoalLiters: waterGoal,
        meals: meals,
      );
    }, whileDoing: 'loading your diet plan');
  }

  Future<Set<String>> _loggedMealIds(
    String memberId,
    String planId,
    String dayKey,
  ) async {
    final snapshot = await _db
        .collection(FirestorePaths.dietLogs)
        .where('memberId', isEqualTo: memberId)
        .where('dietPlanId', isEqualTo: planId)
        .where('loggedDate', isEqualTo: dayKey)
        .where('consumed', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => Val.toText(doc.data()['mealId']))
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<double> _waterForDay(String memberId, String dayKey) async {
    final doc = await _db
        .collection(FirestorePaths.waterLogs)
        .doc('${memberId}_$dayKey')
        .get();
    return Val.toDouble(doc.data()?['liters']);
  }

  Future<void> addWater(double liters, {DateTime? date}) {
    return guard(() async {
      final uid = _uid;
      final dayKey = Val.dayKey(date ?? DateTime.now());
      await _db
          .collection(FirestorePaths.waterLogs)
          .doc('${uid}_$dayKey')
          .set({
            'memberId': uid,
            'loggedDate': dayKey,
            'liters': liters.clamp(0, 20),
            ...BaseFields.onUpdate(),
          }, SetOptions(merge: true));
    }, whileDoing: 'saving your water log');
  }

  Future<void> setMealLogged(DietMeal meal, bool logged, {DateTime? date}) {
    return guard(() async {
      final uid = _uid;
      final mealId = meal.id;
      if (mealId == null || mealId.isEmpty) {
        throw const RepositoryFailure(
          FailureKind.invalid,
          'Open an assigned meal first.',
        );
      }
      final dayKey = Val.dayKey(date ?? DateTime.now());
      await _db
          .collection(FirestorePaths.dietLogs)
          .doc('${uid}_${mealId}_$dayKey')
          .set({
            'memberId': uid,
            'mealId': mealId,
            'loggedDate': dayKey,
            'consumed': logged,
            'consumedAt': logged ? FieldValue.serverTimestamp() : null,
            ...BaseFields.onUpdate(),
          }, SetOptions(merge: true));
    }, whileDoing: 'saving your meal');
  }

  Future<List<NutritionPlan>> fetchSavedDietPlans({int limit = 8}) {
    return guard(() async {
      final uid = _uid;
      final page = await fetchPage<NutritionPlan>(
        query: _db
            .collection(FirestorePaths.dietPlans)
            .where(BaseFields.createdBy, isEqualTo: uid)
            .orderBy(BaseFields.createdAt, descending: true),
        fromDoc: _nutritionPlanFromDoc,
        limit: limit,
      );
      return page.items;
    }, whileDoing: 'loading your saved diet plans');
  }

  NutritionPlan _nutritionPlanFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final meals = <DietMeal>[
      for (final raw in Val.toMapList(data['meals']))
        DietMeal(
          id: Val.toText(raw['id']),
          name: Val.toText(raw['name'], fallback: 'Meal'),
          time: Val.toText(raw['time']),
          description: Val.toText(raw['description']),
          calories: Val.toInt(raw['calories']),
          icon: Val.toText(raw['name']).toLowerCase(),
        ),
    ];
    final consumed = meals.fold<int>(0, (total, meal) => total + meal.calories);
    final goal = Val.toInt(data['dailyCalories'], fallback: consumed);

    return NutritionPlan(
      calories: consumed,
      goalCalories: goal,
      protein: Val.toInt(data['proteinG']),
      carbs: Val.toInt(data['carbsG']),
      fats: Val.toInt(data['fatsG']),
      caloriesLeft: (goal - consumed).clamp(0, goal),
      waterLiters: 0,
      waterGoalLiters: 0,
      meals: meals,
    );
  }

  Future<void> saveDietPlan({
    required String memberId,
    required String name,
    required int dailyCalories,
    required int protein,
    required int carbs,
    required int fats,
    required List<DietMeal> meals,
  }) {
    return guard(() async {
      final uid = _uid;
      await _db.collection(FirestorePaths.dietPlans).add({
        'memberId': memberId,
        'title': name,
        'dailyCalories': dailyCalories,
        'proteinG': protein,
        'carbsG': carbs,
        'fatsG': fats,
        'scheduledDate': Val.dayKey(DateTime.now()),
        'meals': [
          for (var i = 0; i < meals.length; i++)
            {
              'id': '$i',
              'name': meals[i].name,
              'time': meals[i].time,
              'description': meals[i].description,
              'calories': meals[i].calories,
              'order': i,
            },
        ],
        ...BaseFields.onCreate(by: uid),
      });
    }, whileDoing: 'saving the diet plan');
  }

  Future<void> createQuickDietPlan(String memberId) async {
    final meals = await fetchMealTemplates();
    if (meals.isEmpty) {
      throw const RepositoryFailure(
        FailureKind.invalid,
        'Create or save diet meals first.',
      );
    }
    await saveDietPlan(
      memberId: memberId,
      name: 'Quick Diet',
      dailyCalories: meals.fold<int>(0, (total, meal) => total + meal.calories),
      protein: 0,
      carbs: 0,
      fats: 0,
      meals: meals.take(3).toList(),
    );
  }

  Future<List<DietMeal>> fetchMealTemplates() {
    return guard(() async {
      final plans = await fetchSavedDietPlans(limit: 10);
      final seen = <String>{};
      return [
        for (final plan in plans)
          for (final meal in plan.meals)
            if (seen.add(meal.name.toLowerCase())) meal,
      ].take(30).toList();
    }, whileDoing: 'loading your meals');
  }

  // ------------------------------------------------------------------ helpers

  List<ExerciseLog> _defaultLogs(Exercise exercise) {
    final reps = int.tryParse(exercise.reps.split('-').first) ?? 10;
    return [
      for (var i = 1; i <= exercise.sets.clamp(1, 5); i++)
        ExerciseLog(
          setNumber: i,
          weight: exercise.tracksWeight ? exercise.targetWeight : 0,
          reps: reps,
          completed: false,
        ),
    ];
  }

  WorkoutPlan _emptyWorkout({String? name}) {
    return WorkoutPlan(
      id: 'empty',
      name: name ?? 'No Workout Assigned',
      focus: 'Ask your trainer to assign a plan',
      durationMinutes: 0,
      estimatedCalories: 0,
      level: '',
      completionPercent: 0,
      exercises: const [],
    );
  }

  NutritionPlan _emptyNutrition({
    double waterLiters = 0,
    double waterGoalLiters = 0,
  }) {
    return NutritionPlan(
      calories: 0,
      goalCalories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
      caloriesLeft: 0,
      waterLiters: waterLiters,
      waterGoalLiters: waterGoalLiters,
      meals: const [],
    );
  }

  int _macroConsumed(int planned, int consumedCalories, int goalCalories) {
    if (planned <= 0 || consumedCalories <= 0 || goalCalories <= 0) return 0;
    return (planned * (consumedCalories / goalCalories)).round();
  }

  static int _estimatedDurationMinutes(List<Exercise> exercises) {
    final seconds = exercises.fold<int>(0, (total, exercise) {
      final sets = exercise.sets <= 0 ? 1 : exercise.sets;
      final restSeconds = exercise.restSeconds <= 0 ? 60 : exercise.restSeconds;
      return total + (sets * 45) + ((sets - 1) * restSeconds);
    });
    return seconds <= 0 ? 0 : (seconds + 59) ~/ 60;
  }

  static String _mainMuscleGroup(String value) {
    final muscle = value.toLowerCase();
    if (muscle.contains('chest') || muscle.contains('pector')) return 'Chest';
    if (muscle.contains('back') ||
        muscle.contains('lat') ||
        muscle.contains('trap') ||
        muscle.contains('neck')) {
      return 'Back';
    }
    if (muscle.contains('quad') ||
        muscle.contains('hamstring') ||
        muscle.contains('glute') ||
        muscle.contains('calf') ||
        muscle.contains('leg') ||
        muscle.contains('abductor') ||
        muscle.contains('adductor')) {
      return 'Legs';
    }
    if (muscle.contains('shoulder') || muscle.contains('delt')) {
      return 'Shoulders';
    }
    if (muscle.contains('bicep') ||
        muscle.contains('tricep') ||
        muscle.contains('forearm')) {
      return 'Arms';
    }
    if (muscle.contains('ab') ||
        muscle.contains('core') ||
        muscle.contains('oblique')) {
      return 'Core';
    }
    if (muscle.contains('cardio')) return 'Cardio';
    return value.trim().isEmpty ? 'Full Body' : _titleCase(value);
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class ExerciseLogsController extends AsyncNotifier<List<ExerciseLog>> {
  @override
  Future<List<ExerciseLog>> build() async {
    final exercise = ref.watch(selectedExerciseProvider);
    if (exercise == null) return const [];
    return ref.watch(appDataRepositoryProvider).fetchExerciseLogs(exercise);
  }

  void updateAt(int index, ExerciseLog log) {
    final current = state.value ?? const <ExerciseLog>[];
    state = AsyncData([...current]..[index] = log);
  }

  void updateBySetNumber(ExerciseLog log) {
    final current = [...(state.value ?? const <ExerciseLog>[])];
    final index = current.indexWhere((item) => item.setNumber == log.setNumber);
    if (index < 0) return;
    current[index] = log;
    current.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    state = AsyncData(current);
  }

  void addExtraSet() {
    final current = state.value ?? const <ExerciseLog>[];
    final last = current.isEmpty ? 0 : current.last.setNumber;
    state = AsyncData([
      ...current,
      ExerciseLog(setNumber: last + 1, weight: 0, reps: 0),
    ]);
  }

  Future<void> save(Exercise exercise) async {
    final current = [...(state.value ?? const <ExerciseLog>[])]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    await ref
        .read(appDataRepositoryProvider)
        .saveExerciseLogs(exercise, current);
  }

  Future<void> completeAllAndSave(Exercise exercise) async {
    final current = [...(state.value ?? const <ExerciseLog>[])]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final completed = current
        .map(
          (log) => ExerciseLog(
            id: log.id,
            setNumber: log.setNumber,
            weight: log.weight,
            reps: log.reps,
            completed: true,
          ),
        )
        .toList();
    state = AsyncData(completed);
    await ref
        .read(appDataRepositoryProvider)
        .saveExerciseLogs(exercise, completed);
  }

  /// Writes the completion log and advances the plan's unlock.
  Future<void> finishExercise({
    required WorkoutPlan workout,
    required Exercise exercise,
  }) async {
    final current = [...(state.value ?? const <ExerciseLog>[])]
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final completed = current
        .map(
          (log) => ExerciseLog(
            id: log.id,
            setNumber: log.setNumber,
            weight: log.weight,
            reps: log.reps,
            completed: true,
          ),
        )
        .toList();
    state = AsyncData(completed);

    final repository = ref.read(appDataRepositoryProvider);
    await repository.saveExerciseLogs(exercise, completed);
    await repository.completeExercise(
      workout: workout,
      exercise: exercise,
      logs: completed,
    );
    ref.invalidate(workoutProvider);
  }
}
