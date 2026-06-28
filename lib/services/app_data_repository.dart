import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/services/supabase_service.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(ref.watch(supabaseServiceProvider)),
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
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchCurrentUser();
});

final workoutProvider = FutureProvider<WorkoutPlan>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchTodayWorkout();
});

final nutritionProvider = FutureProvider<NutritionPlan>((ref) {
  ref.watch(currentAuthUserIdProvider);
  final date = ref.watch(nutritionDateProvider);
  return ref.watch(appDataRepositoryProvider).fetchNutritionPlan(date: date);
});

final todayNutritionProvider = FutureProvider<NutritionPlan>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchNutritionPlan();
});

final nutritionDateProvider =
    NotifierProvider<NutritionDateController, DateTime>(
      NutritionDateController.new,
    );

final progressProvider = FutureProvider<MemberProgress>((ref) {
  ref.watch(currentAuthUserIdProvider);
  final range = ref.watch(progressDateRangeProvider);
  return ref
      .watch(appDataRepositoryProvider)
      .fetchProgress(startDate: range?.start, endDate: range?.end);
});

final progressDateRangeProvider =
    NotifierProvider<
      ProgressDateRangeController,
      ({DateTime start, DateTime end})?
    >(ProgressDateRangeController.new);

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchSettings();
});

final membersProvider = FutureProvider<List<MemberSummary>>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchMembers();
});

final exerciseLibraryProvider = FutureProvider<List<Exercise>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchExerciseLibrary(),
);

final trainerStatsProvider = FutureProvider<TrainerDashboardStats>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchTrainerStats();
});

final savedWorkoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchSavedWorkoutPlans();
});

final savedDietPlansProvider = FutureProvider<List<NutritionPlan>>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchSavedDietPlans();
});

final mealTemplatesProvider = FutureProvider<List<DietMeal>>((ref) {
  ref.watch(currentAuthUserIdProvider);
  return ref.watch(appDataRepositoryProvider).fetchMealTemplates();
});

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
}

final exerciseLogsProvider =
    AsyncNotifierProvider<ExerciseLogsController, List<ExerciseLog>>(
      ExerciseLogsController.new,
    );

class AppDataRepository {
  const AppDataRepository(this._supabaseService);

  final SupabaseService _supabaseService;

  bool get _hasClient => _supabaseService.isConfigured;

  String? get _authUserId {
    if (!_hasClient) return null;
    return _supabaseService.client.auth.currentUser?.id;
  }

  void _requireClient() {
    if (!_hasClient) throw StateError('Supabase is not configured.');
  }

  Future<AppUser> fetchCurrentUser() async {
    final authUser = _hasClient
        ? _supabaseService.client.auth.currentUser
        : null;
    if (authUser == null) throw StateError('You are not logged in.');

    final row = await _supabaseService.client
        .from('users')
        .select('id,name,email,phone,avatar_url,role,created_at')
        .eq('id', authUser.id)
        .maybeSingle();

    if (row == null) {
      await _supabaseService.client.auth.signOut();
      throw StateError(
        'Your saved session no longer matches an active profile. Please sign in again.',
      );
    }

    final role = row['role'] == 'trainer' ? UserRole.trainer : UserRole.member;
    String? trainerName;
    String? goal;
    double? heightCm;

    if (role == UserRole.member) {
      final memberRow = await _supabaseService.client
          .from('members')
          .select('goal,height_cm,age,trainer_id,trainers(name)')
          .eq('id', authUser.id)
          .maybeSingle();
      goal = memberRow?['goal']?.toString();
      heightCm = _toNullableDouble(memberRow?['height_cm']);
      final age = _toNullableInt(memberRow?['age']);
      final trainer = memberRow?['trainers'];
      if (trainer is Map) trainerName = trainer['name']?.toString();
      final trainerId = memberRow?['trainer_id']?.toString();
      if ((trainerName == null || trainerName.trim().isEmpty) &&
          trainerId != null &&
          trainerId.isNotEmpty) {
        final trainerRow = await _supabaseService.client
            .from('trainers')
            .select('name')
            .eq('id', trainerId)
            .maybeSingle();
        trainerName = trainerRow?['name']?.toString();
      }
      return AppUser(
        id: row['id'].toString(),
        name: row['name'].toString(),
        email: (row['email'] ?? '').toString(),
        role: role,
        createdAt: _toDateTime(row['created_at']),
        phone: row['phone']?.toString(),
        avatarUrl: row['avatar_url']?.toString(),
        trainerName: trainerName,
        goal: goal,
        heightCm: heightCm,
        age: age,
      );
    }

    return AppUser(
      id: row['id'].toString(),
      name: row['name'].toString(),
      email: (row['email'] ?? '').toString(),
      role: role,
      createdAt: _toDateTime(row['created_at']),
      phone: row['phone']?.toString(),
      avatarUrl: row['avatar_url']?.toString(),
      trainerName: trainerName,
      goal: goal,
      heightCm: heightCm,
    );
  }

  Future<WorkoutPlan> fetchTodayWorkout({String? memberId}) async {
    _requireClient();
    final userId = memberId ?? _authUserId;
    if (userId == null) throw StateError('You are not logged in.');

    final plan = await _supabaseService.client
        .from('workout_plans')
        .select()
        .eq('member_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (plan == null) return _emptyWorkout();

    final day = await _supabaseService.client
        .from('workout_days')
        .select()
        .eq('workout_plan_id', plan['id'])
        .order('scheduled_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (day == null) return _emptyWorkout(name: plan['name']?.toString());

    final rows = await _supabaseService.client
        .from('workout_exercises')
        .select(
          'id,sets,reps,rest_seconds,target_weight_kg,trainer_notes,sort_order,exercises(id,source_id,name,description,muscle_group,default_sets,default_reps,tracks_weight,rest_seconds,equipment,level,category,primary_muscles,secondary_muscles,instructions,image_urls)',
        )
        .eq('workout_day_id', day['id'])
        .order('sort_order');

    final exercises = rows.map<Exercise>((row) {
      final exercise = row['exercises'] as Map<String, dynamic>;
      return _exerciseFromRow(
        exercise,
        workoutExerciseId: row['id'].toString(),
        sets: _toInt(row['sets']),
        reps: row['reps'].toString(),
        restSeconds: _toInt(row['rest_seconds']),
        targetWeight: _toInt(row['target_weight_kg']),
        notes: (row['trainer_notes'] ?? '').toString(),
      );
    }).toList();

    final workoutExerciseIds = exercises
        .map((exercise) => exercise.workoutExerciseId)
        .whereType<String>()
        .toList();
    final completedSetsByExercise = await _completedSetsByWorkoutExercise(
      userId,
      workoutExerciseIds,
    );
    final enrichedExercises = exercises
        .map(
          (exercise) => _exerciseWithCompletedSets(
            exercise,
            completedSetsByExercise[exercise.workoutExerciseId] ?? 0,
          ),
        )
        .toList();
    final totalSets = exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets,
    );

    return WorkoutPlan(
      id: plan['id'].toString(),
      name: (day['title'] ?? plan['name']).toString(),
      focus: (plan['focus'] ?? 'Assigned Program').toString(),
      durationMinutes: _toInt(day['duration_minutes']),
      estimatedCalories: _toInt(plan['estimated_calories']),
      level: (plan['level'] ?? '').toString(),
      completionPercent: _completionFromCounts(enrichedExercises, totalSets),
      exercises: enrichedExercises,
    );
  }

  Future<NutritionPlan> fetchNutritionPlan({
    String? memberId,
    DateTime? date,
  }) async {
    _requireClient();
    final userId = memberId ?? _authUserId;
    if (userId == null) throw StateError('You are not logged in.');
    final selectedDate = date ?? DateTime.now();
    final waterGoal = await _fetchWaterGoal(userId);
    final waterLiters = await _fetchWaterLitersForDate(userId, selectedDate);

    final plan = await _supabaseService.client
        .from('diet_plans')
        .select()
        .eq('member_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (plan == null) {
      return _emptyNutrition(
        waterLiters: waterLiters,
        waterGoalLiters: waterGoal,
      );
    }

    final mealRows = await _supabaseService.client
        .from('diet_meals')
        .select()
        .eq('diet_plan_id', plan['id'])
        .order('sort_order');

    final selectedDay = _dateKey(selectedDate);
    final mealIds = mealRows
        .map<String>((row) => row['id'].toString())
        .toList();
    final loggedMealIds = mealIds.isEmpty
        ? <String>{}
        : (await _supabaseService.client
                  .from('diet_logs')
                  .select('diet_meal_id')
                  .eq('member_id', userId)
                  .eq('logged_date', selectedDay)
                  .eq('consumed', true)
                  .inFilter('diet_meal_id', mealIds))
              .map<String>((row) => row['diet_meal_id'].toString())
              .toSet();

    final meals = mealRows.map<DietMeal>((row) {
      final mealId = row['id'].toString();
      return DietMeal(
        id: mealId,
        name: row['name'].toString(),
        time: _formatTime(row['meal_time']?.toString()),
        description: (row['description'] ?? '').toString(),
        calories: _toInt(row['calories']),
        icon: row['name'].toString().toLowerCase(),
        logged: loggedMealIds.contains(mealId),
      );
    }).toList();

    final consumed = meals
        .where((meal) => meal.logged)
        .fold<int>(0, (sum, meal) => sum + meal.calories);
    final goal = _toInt(plan['daily_calories']);

    return NutritionPlan(
      calories: consumed,
      goalCalories: goal,
      protein: _macroConsumed(_toInt(plan['protein_g']), consumed, goal),
      carbs: _macroConsumed(_toInt(plan['carbs_g']), consumed, goal),
      fats: _macroConsumed(_toInt(plan['fats_g']), consumed, goal),
      caloriesLeft: (goal - consumed).clamp(0, goal),
      waterLiters: waterLiters,
      waterGoalLiters: waterGoal,
      meals: meals,
    );
  }

  Future<MemberProgress> fetchProgress({
    String? memberId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireClient();
    final userId = memberId ?? _authUserId;
    if (userId == null) throw StateError('You are not logged in.');

    final measurements = await _supabaseService.client
        .from('measurements')
        .select()
        .eq('member_id', userId)
        .order('measured_at', ascending: false)
        .limit(2);
    final currentWeight = measurements.isNotEmpty
        ? _toDouble(measurements.first['weight'])
        : 0.0;
    final previousWeight = measurements.length > 1
        ? _toDouble(measurements[1]['weight'], fallback: currentWeight)
        : currentWeight;

    var logsQuery = _supabaseService.client
        .from('exercise_logs')
        .select(
          'weight,reps,completed,logged_at,exercises(name,muscle_group,tracks_weight)',
        )
        .eq('member_id', userId);

    if (startDate != null) {
      logsQuery = logsQuery.gte('logged_at', _startOfDay(startDate));
    }
    if (endDate != null) {
      logsQuery = logsQuery.lt('logged_at', _dayAfter(endDate));
    }

    final logs = await logsQuery.order('logged_at', ascending: false);

    final allCompletions = await _supabaseService.client
        .from('workout_completions')
        .select('id')
        .eq('member_id', userId);
    final completedLogs = logs.where((row) => row['completed'] != false);

    final personalBests = <String, int>{};
    final muscleCounts = <String, int>{};
    for (final row in completedLogs) {
      final exercise = row['exercises'];
      if (exercise is! Map) continue;
      final name = exercise['name'].toString();
      final muscle = _mainMuscleGroup(exercise['muscle_group'].toString());
      final weight = _toInt(row['weight']);
      if (exercise['tracks_weight'] != false &&
          weight > 0 &&
          (!personalBests.containsKey(name) || weight > personalBests[name]!)) {
        personalBests[name] = weight;
      }
      muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + 1;
    }
    final sortedMuscles = muscleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedBests = personalBests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MemberProgress(
      currentWeight: currentWeight,
      weightDelta: double.parse(
        (currentWeight - previousWeight).toStringAsFixed(1),
      ),
      workoutsCompleted: allCompletions.length,
      goalCompletion: await _latestWorkoutCompletion(userId),
      dayStreak: _dayStreakFromLogs(logs),
      muscleProgress: Map.fromEntries(
        sortedMuscles
            .take(6)
            .map(
              (entry) => MapEntry(entry.key, (entry.value * 7).clamp(8, 100)),
            ),
      ),
      personalBests: Map.fromEntries(sortedBests.take(6)),
    );
  }

  Future<AppSettings> fetchSettings() async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final row = await _supabaseService.client
        .from('users')
        .select('notifications_enabled,preferred_unit')
        .eq('id', _authUserId!)
        .maybeSingle();
    return AppSettings(
      notificationsEnabled: row?['notifications_enabled'] != false,
      preferredUnit: (row?['preferred_unit'] ?? 'kg').toString(),
    );
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    await _supabaseService.client
        .from('users')
        .update({'notifications_enabled': enabled})
        .eq('id', _authUserId!);
  }

  Future<void> updatePreferredUnit(String unit) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    await _supabaseService.client
        .from('users')
        .update({'preferred_unit': unit})
        .eq('id', _authUserId!);
  }

  Future<void> addWater(double liters, {DateTime? date}) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final selectedDay = _dateKey(date ?? DateTime.now());
    await _supabaseService.client.from('water_logs').upsert({
      'member_id': _authUserId,
      'logged_date': selectedDay,
      'liters': liters.clamp(0, 20),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'member_id,logged_date');
  }

  Future<List<MemberSummary>> fetchMembers() async {
    _requireClient();

    final rows = await _supabaseService.client
        .from('members')
        .select(
          'id,goal,height_cm,users(name,email,phone,avatar_url),trainers(name),measurements(weight,measured_at)',
        )
        .order('created_at');

    return rows.map<MemberSummary>((row) {
      final user = row['users'] as Map?;
      final trainer = row['trainers'] as Map?;
      final measurements = row['measurements'];
      double weight = 0;
      if (measurements is List && measurements.isNotEmpty) {
        weight = _toDouble(measurements.first['weight'], fallback: weight);
      }
      return MemberSummary(
        id: row['id'].toString(),
        name: (user?['name'] ?? 'Member').toString(),
        email: (user?['email'] ?? '').toString(),
        phone: user?['phone']?.toString(),
        avatarUrl: user?['avatar_url']?.toString(),
        goal: (row['goal'] ?? 'Fitness').toString(),
        heightCm: _toDouble(row['height_cm']),
        currentWeight: weight,
        trainerName: (trainer?['name'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<Exercise>> fetchExerciseLibrary() async {
    _requireClient();
    final rows = await _supabaseService.client
        .from('exercises')
        .select()
        .order('muscle_group')
        .order('name');
    return rows.map<Exercise>((row) {
      return _exerciseFromRow(
        row,
        sets: _toInt(row['default_sets']),
        reps: (row['default_reps'] ?? '').toString(),
        notes: '',
        isAssigned: false,
      );
    }).toList();
  }

  Future<TrainerDashboardStats> fetchTrainerStats() async {
    final members = await fetchMembers();
    final plans = await _supabaseService.client
        .from('workout_plans')
        .select('id');
    return TrainerDashboardStats(
      memberCount: members.length,
      activePlanCount: plans.length,
    );
  }

  Future<List<WorkoutPlan>> fetchSavedWorkoutPlans() async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final rows = await _supabaseService.client
        .from('workout_plans')
        .select('id')
        .eq('trainer_id', _authUserId!)
        .order('created_at', ascending: false)
        .limit(8);
    final plans = <WorkoutPlan>[];
    for (final row in rows) {
      plans.add(await _fetchWorkoutPlanById(row['id'].toString()));
    }
    return plans;
  }

  Future<List<NutritionPlan>> fetchSavedDietPlans() async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final rows = await _supabaseService.client
        .from('diet_plans')
        .select('id')
        .eq('trainer_id', _authUserId!)
        .order('created_at', ascending: false)
        .limit(8);
    final plans = <NutritionPlan>[];
    for (final row in rows) {
      plans.add(await _fetchDietPlanById(row['id'].toString()));
    }
    return plans;
  }

  Future<List<ExerciseLog>> fetchExerciseLogs(Exercise exercise) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    var query = _supabaseService.client
        .from('exercise_logs')
        .select()
        .eq('member_id', _authUserId!);
    final workoutExerciseId = exercise.workoutExerciseId;
    if (workoutExerciseId != null) {
      query = query.eq('workout_exercise_id', workoutExerciseId);
    } else {
      query = query.eq('exercise_id', exercise.id);
    }
    final rows = await query.order('set_number', ascending: true);
    if (rows.isEmpty) return _defaultLogs(exercise);
    final logs = rows.map<ExerciseLog>((row) {
      return ExerciseLog(
        id: row['id'].toString(),
        setNumber: _toInt(row['set_number']),
        weight: _toInt(row['weight']),
        reps: _toInt(row['reps']),
        completed: row['completed'] != false,
      );
    }).toList();
    logs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return logs;
  }

  Future<void> saveExerciseLogs(
    Exercise exercise,
    List<ExerciseLog> logs,
  ) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final uniqueLogs = <int, ExerciseLog>{};
    for (final log in logs) {
      uniqueLogs[log.setNumber] = log;
    }
    final sortedLogs = uniqueLogs.values.toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    final payload = sortedLogs.map((log) {
      return {
        'member_id': _authUserId,
        'workout_exercise_id': exercise.workoutExerciseId,
        'exercise_id': exercise.id,
        'set_number': log.setNumber,
        'weight': log.weight,
        'reps': log.reps,
        'completed': log.completed,
      };
    }).toList();
    await _supabaseService.client
        .from('exercise_logs')
        .upsert(
          payload,
          onConflict: 'member_id,workout_exercise_id,set_number',
        );
  }

  Future<void> completeWorkout(WorkoutPlan workout) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    if (workout.id == 'empty') return;
    final latestDay = await _supabaseService.client
        .from('workout_days')
        .select('id')
        .eq('workout_plan_id', workout.id)
        .order('scheduled_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (latestDay == null) return;
    final today = _dateKey(DateTime.now());
    await _supabaseService.client.from('workout_completions').upsert({
      'member_id': _authUserId,
      'workout_plan_id': workout.id,
      'workout_day_id': latestDay['id'],
      'completed_date': today,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'member_id,workout_plan_id,workout_day_id,completed_date');
  }

  Future<void> setMealLogged(
    DietMeal meal,
    bool logged, {
    DateTime? date,
  }) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final mealId = meal.id;
    if (mealId == null) throw StateError('Open an assigned meal first.');
    final row = await _supabaseService.client
        .from('diet_meals')
        .select('diet_plan_id')
        .eq('id', mealId)
        .single();
    final selectedDay = _dateKey(date ?? DateTime.now());
    await _supabaseService.client.from('diet_logs').upsert({
      'member_id': _authUserId,
      'diet_plan_id': row['diet_plan_id'],
      'diet_meal_id': mealId,
      'logged_date': selectedDay,
      'consumed': logged,
      'consumed_at': logged ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'member_id,diet_meal_id,logged_date');
  }

  Future<void> saveExerciseNote(Exercise exercise, String note) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final workoutExerciseId = exercise.workoutExerciseId;
    if (workoutExerciseId == null) {
      throw StateError(
        'Open an assigned workout exercise before saving notes.',
      );
    }
    await _supabaseService.client.from('exercise_notes').upsert({
      'member_id': _authUserId,
      'workout_exercise_id': workoutExerciseId,
      'exercise_id': exercise.id,
      'note': note.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'member_id,workout_exercise_id,exercise_id');
  }

  Future<String> fetchExerciseNote(Exercise exercise) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final workoutExerciseId = exercise.workoutExerciseId;
    if (workoutExerciseId == null) return '';
    final row = await _supabaseService.client
        .from('exercise_notes')
        .select('note')
        .eq('member_id', _authUserId!)
        .eq('exercise_id', exercise.id)
        .eq('workout_exercise_id', workoutExerciseId)
        .maybeSingle();
    return (row?['note'] ?? '').toString();
  }

  Future<void> resetWorkoutProgress(WorkoutPlan workout) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final workoutExerciseIds = workout.exercises
        .map((exercise) => exercise.workoutExerciseId)
        .whereType<String>()
        .toList();
    if (workoutExerciseIds.isEmpty) return;
    await _supabaseService.client
        .from('exercise_logs')
        .delete()
        .eq('member_id', _authUserId!)
        .inFilter('workout_exercise_id', workoutExerciseIds);
    await _supabaseService.client
        .from('exercise_notes')
        .delete()
        .eq('member_id', _authUserId!)
        .inFilter('workout_exercise_id', workoutExerciseIds);
    await _supabaseService.client
        .from('workout_completions')
        .delete()
        .eq('member_id', _authUserId!)
        .eq('workout_plan_id', workout.id);
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
        '- ${exercise.name}: ${exercise.sets} sets x ${exercise.reps}, rest ${exercise.restSeconds}s',
      );
    }
    return buffer.toString().trim();
  }

  Future<void> createQuickWorkoutPlan(String memberId) async {
    final exercises = await fetchExerciseLibrary();
    if (exercises.isEmpty) throw StateError('Add exercises first.');
    await saveWorkoutPlan(
      memberId: memberId,
      name: 'Quick Workout',
      focus: 'Assigned Workout',
      exercises: exercises.take(4).toList(),
    );
  }

  Future<void> saveWorkoutPlan({
    required String memberId,
    required String name,
    required String focus,
    required List<Exercise> exercises,
  }) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final durationMinutes = _estimatedDurationMinutes(exercises);
    final plan = await _supabaseService.client
        .from('workout_plans')
        .insert({
          'trainer_id': _authUserId,
          'member_id': memberId,
          'name': name,
          'focus': focus,
          'estimated_calories': durationMinutes * 8,
        })
        .select('id')
        .single();
    final day = await _supabaseService.client
        .from('workout_days')
        .insert({
          'workout_plan_id': plan['id'],
          'scheduled_date': DateTime.now().toIso8601String().substring(0, 10),
          'title': name,
          'duration_minutes': durationMinutes,
        })
        .select('id')
        .single();
    await _supabaseService.client.from('workout_exercises').insert([
      for (var i = 0; i < exercises.length; i++)
        {
          'workout_day_id': day['id'],
          'exercise_id': exercises[i].id,
          'sort_order': i + 1,
          'sets': exercises[i].sets,
          'reps': exercises[i].reps,
          'target_weight_kg': exercises[i].tracksWeight
              ? exercises[i].targetWeight
              : 0,
          'rest_seconds': exercises[i].restSeconds,
          'trainer_notes': exercises[i].notes.isEmpty
              ? 'Controlled reps. Leave one rep in reserve.'
              : exercises[i].notes,
        },
    ]);
  }

  Future<void> createQuickDietPlan(String memberId) async {
    final meals = await fetchMealTemplates();
    if (meals.isEmpty) throw StateError('Create or save diet meals first.');
    await saveDietPlan(
      memberId: memberId,
      name: 'Quick Diet',
      dailyCalories: meals.fold<int>(0, (sum, meal) => sum + meal.calories),
      protein: 0,
      carbs: 0,
      fats: 0,
      meals: meals.take(3).toList(),
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
  }) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final plan = await _supabaseService.client
        .from('diet_plans')
        .insert({
          'trainer_id': _authUserId,
          'member_id': memberId,
          'name': name,
          'daily_calories': dailyCalories,
          'protein_g': protein,
          'carbs_g': carbs,
          'fats_g': fats,
        })
        .select('id')
        .single();
    await _supabaseService.client.from('diet_meals').insert([
      for (var i = 0; i < meals.length; i++)
        {
          'diet_plan_id': plan['id'],
          'name': meals[i].name,
          'meal_time': _toDatabaseTime(meals[i].time),
          'description': meals[i].description,
          'calories': meals[i].calories,
          'sort_order': i + 1,
        },
    ]);
  }

  Future<void> addMeasurement(String memberId, double weight) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    await _supabaseService.client.from('measurements').insert({
      'member_id': memberId,
      'trainer_id': _authUserId,
      'weight': weight,
      'notes': 'Trainer update',
    });
  }

  Future<CreatedMemberInvite> createMember({
    required String name,
    required String? email,
    required String? phone,
    required String password,
    required String goal,
    required int? age,
    required double heightCm,
    required double weight,
  }) async {
    _requireClient();
    final response = await _supabaseService.client.functions.invoke(
      'create-member',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'goal': goal,
        'age': age,
        'height_cm': heightCm,
        'weight': weight,
      },
    );
    if (response.status >= 400) {
      throw StateError(response.data?.toString() ?? 'Could not create member.');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    final memberData = Map<String, dynamic>.from(data['member'] as Map);
    final member = MemberSummary(
      id: memberData['id'].toString(),
      name: memberData['name'].toString(),
      email: (memberData['email'] ?? '').toString(),
      phone: memberData['phone']?.toString(),
      goal: (memberData['goal'] ?? 'Fitness').toString(),
      heightCm: _toDouble(memberData['height_cm'], fallback: heightCm),
      currentWeight: _toDouble(memberData['weight'], fallback: weight),
      trainerName: (memberData['trainer_name'] ?? 'You').toString(),
    );
    return CreatedMemberInvite(
      member: member,
      inviteText: (data['invite_text'] ?? '').toString(),
    );
  }

  Future<List<DietMeal>> fetchMealTemplates() async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final rows = await _supabaseService.client
        .from('diet_meals')
        .select(
          'name,meal_time,description,calories,diet_plans!inner(trainer_id)',
        )
        .eq('diet_plans.trainer_id', _authUserId!)
        .order('name')
        .limit(30);
    final seen = <String>{};
    return rows
        .map<DietMeal>((row) {
          return DietMeal(
            name: row['name'].toString(),
            time: _formatTime(row['meal_time']?.toString()),
            description: (row['description'] ?? '').toString(),
            calories: _toInt(row['calories']),
            icon: row['name'].toString().toLowerCase(),
          );
        })
        .where((meal) => seen.add(meal.name.toLowerCase()))
        .toList();
  }

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

  Future<Map<String, int>> _completedSetsByWorkoutExercise(
    String memberId,
    List<String> workoutExerciseIds,
  ) async {
    if (workoutExerciseIds.isEmpty) return const {};
    final rows = await _supabaseService.client
        .from('exercise_logs')
        .select('workout_exercise_id,completed')
        .eq('member_id', memberId)
        .inFilter('workout_exercise_id', workoutExerciseIds);
    final counts = <String, int>{};
    for (final row in rows) {
      if (row['completed'] == false) continue;
      final id = row['workout_exercise_id']?.toString();
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Exercise _exerciseWithCompletedSets(Exercise exercise, int completedSets) {
    return Exercise(
      id: exercise.id,
      name: exercise.name,
      description: exercise.description,
      muscleGroup: exercise.muscleGroup,
      sets: exercise.sets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      icon: exercise.icon,
      notes: exercise.notes,
      tracksWeight: exercise.tracksWeight,
      targetWeight: exercise.targetWeight,
      workoutExerciseId: exercise.workoutExerciseId,
      isAssigned: exercise.isAssigned,
      sourceId: exercise.sourceId,
      equipment: exercise.equipment,
      level: exercise.level,
      category: exercise.category,
      primaryMuscles: exercise.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles,
      instructions: exercise.instructions,
      imageUrls: exercise.imageUrls,
      completedSetCount: completedSets.clamp(0, exercise.sets),
    );
  }

  double _completionFromCounts(List<Exercise> exercises, int totalSets) {
    if (exercises.isEmpty || totalSets <= 0) return 0;
    final completed = exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum + exercise.completedSetCount.clamp(0, exercise.sets),
    );
    return (completed / totalSets).clamp(0.0, 1.0);
  }

  int _macroConsumed(int planned, int consumedCalories, int goalCalories) {
    if (planned <= 0 || consumedCalories <= 0 || goalCalories <= 0) return 0;
    return (planned * (consumedCalories / goalCalories)).round();
  }

  static int _toInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static DateTime _toDateTime(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
  }

  static String _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  static String _dayAfter(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(const Duration(days: 1)).toIso8601String();
  }

  static int _estimatedDurationMinutes(List<Exercise> exercises) {
    final seconds = exercises.fold<int>(0, (sum, exercise) {
      final sets = exercise.sets <= 0 ? 1 : exercise.sets;
      final restSeconds = exercise.restSeconds <= 0 ? 60 : exercise.restSeconds;
      return sum + (sets * 45) + ((sets - 1) * restSeconds);
    });
    return seconds <= 0 ? 0 : (seconds + 59) ~/ 60;
  }

  static String _mainMuscleGroup(String value) {
    final muscle = value.toLowerCase();
    if (muscle.contains('chest') || muscle.contains('pector')) {
      return 'Chest';
    }
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

  Future<double> _latestWorkoutCompletion(String memberId) async {
    final plan = await _supabaseService.client
        .from('workout_plans')
        .select('id')
        .eq('member_id', memberId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (plan == null) return 0;
    final day = await _supabaseService.client
        .from('workout_days')
        .select('id')
        .eq('workout_plan_id', plan['id'])
        .order('scheduled_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (day == null) return 0;
    final rows = await _supabaseService.client
        .from('workout_exercises')
        .select('id,sets')
        .eq('workout_day_id', day['id']);
    final ids = rows.map<String>((row) => row['id'].toString()).toList();
    final totalSets = rows.fold<int>(
      0,
      (sum, row) => sum + _toInt(row['sets']),
    );
    return _workoutCompletion(memberId, ids, totalSets);
  }

  Future<double> _workoutCompletion(
    String memberId,
    List<String> workoutExerciseIds,
    int totalSets,
  ) async {
    if (workoutExerciseIds.isEmpty || totalSets <= 0) return 0;
    final logs = await _supabaseService.client
        .from('exercise_logs')
        .select('set_number,completed,workout_exercise_id')
        .eq('member_id', memberId)
        .inFilter('workout_exercise_id', workoutExerciseIds);
    final completed = logs.where((row) => row['completed'] != false).length;
    return (completed / totalSets).clamp(0.0, 1.0);
  }

  Future<double> _fetchWaterLitersForDate(
    String memberId,
    DateTime date,
  ) async {
    final loggedDate = date.toIso8601String().substring(0, 10);
    final row = await _supabaseService.client
        .from('water_logs')
        .select('liters')
        .eq('member_id', memberId)
        .eq('logged_date', loggedDate)
        .maybeSingle();
    return _toDouble(row?['liters']);
  }

  Future<double> _fetchWaterGoal(String memberId) async {
    final row = await _supabaseService.client
        .from('members')
        .select('water_goal_liters')
        .eq('id', memberId)
        .maybeSingle();
    return _toDouble(row?['water_goal_liters']);
  }

  int _dayStreakFromLogs(List<dynamic> logs) {
    final dates = <DateTime>{};
    for (final row in logs) {
      if (row is! Map || row['completed'] == false) continue;
      final loggedAt = DateTime.tryParse(row['logged_at'].toString());
      if (loggedAt == null) continue;
      dates.add(DateTime(loggedAt.year, loggedAt.month, loggedAt.day));
    }
    if (dates.isEmpty) return 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!dates.contains(cursor)) {
      final yesterday = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(yesterday)) return 0;
      cursor = yesterday;
    }
    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $suffix';
  }

  static String _toDatabaseTime(String value) {
    final trimmed = value.trim();
    if (trimmed.contains(':') && !trimmed.contains(' ')) return trimmed;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) return '08:00';
    var hour = int.tryParse(match.group(1) ?? '8') ?? 8;
    final minute = match.group(2) ?? '00';
    final suffix = (match.group(3) ?? 'AM').toUpperCase();
    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  Future<WorkoutPlan> _fetchWorkoutPlanById(String planId) async {
    final plan = await _supabaseService.client
        .from('workout_plans')
        .select()
        .eq('id', planId)
        .single();
    final day = await _supabaseService.client
        .from('workout_days')
        .select()
        .eq('workout_plan_id', planId)
        .order('scheduled_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (day == null) return _emptyWorkout(name: plan['name']?.toString());
    final rows = await _supabaseService.client
        .from('workout_exercises')
        .select(
          'id,sets,reps,rest_seconds,target_weight_kg,trainer_notes,sort_order,exercises(id,source_id,name,description,muscle_group,default_sets,default_reps,tracks_weight,rest_seconds,equipment,level,category,primary_muscles,secondary_muscles,instructions,image_urls)',
        )
        .eq('workout_day_id', day['id'])
        .order('sort_order');
    final exercises = rows.map<Exercise>((row) {
      final exercise = row['exercises'] as Map<String, dynamic>;
      return _exerciseFromRow(
        exercise,
        workoutExerciseId: row['id'].toString(),
        sets: _toInt(row['sets']),
        reps: row['reps'].toString(),
        restSeconds: _toInt(row['rest_seconds']),
        targetWeight: _toInt(row['target_weight_kg']),
        notes: (row['trainer_notes'] ?? '').toString(),
      );
    }).toList();
    return WorkoutPlan(
      id: plan['id'].toString(),
      name: (day['title'] ?? plan['name']).toString(),
      focus: (plan['focus'] ?? 'Assigned Program').toString(),
      durationMinutes: _toInt(day['duration_minutes']),
      estimatedCalories: _toInt(plan['estimated_calories']),
      level: (plan['level'] ?? '').toString(),
      completionPercent: 0,
      exercises: exercises,
    );
  }

  Future<NutritionPlan> _fetchDietPlanById(String planId) async {
    final plan = await _supabaseService.client
        .from('diet_plans')
        .select()
        .eq('id', planId)
        .single();
    final rows = await _supabaseService.client
        .from('diet_meals')
        .select()
        .eq('diet_plan_id', planId)
        .order('sort_order');
    final meals = rows.map<DietMeal>((row) {
      return DietMeal(
        name: row['name'].toString(),
        time: _formatTime(row['meal_time']?.toString()),
        description: (row['description'] ?? '').toString(),
        calories: _toInt(row['calories']),
        icon: row['name'].toString().toLowerCase(),
      );
    }).toList();
    final consumed = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final goal = _toInt(plan['daily_calories'], fallback: consumed);
    return NutritionPlan(
      calories: consumed,
      goalCalories: goal,
      protein: _toInt(plan['protein_g']),
      carbs: _toInt(plan['carbs_g']),
      fats: _toInt(plan['fats_g']),
      caloriesLeft: (goal - consumed).clamp(0, goal),
      waterLiters: 0,
      waterGoalLiters: 0,
      meals: meals,
    );
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

  Exercise _exerciseFromRow(
    Map<String, dynamic> row, {
    required int sets,
    required String reps,
    String? workoutExerciseId,
    int? restSeconds,
    int? targetWeight,
    String notes = '',
    bool isAssigned = true,
  }) {
    final muscleGroup = row['muscle_group'].toString();
    final instructions = _toStringList(row['instructions']);
    final description = (row['description'] ?? '').toString().trim();
    return Exercise(
      id: row['id'].toString(),
      workoutExerciseId: workoutExerciseId,
      name: row['name'].toString(),
      description: description.isNotEmpty
          ? description
          : instructions.take(2).join(' '),
      muscleGroup: muscleGroup,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds ?? _toInt(row['rest_seconds'], fallback: 60),
      icon: muscleGroup.toLowerCase(),
      notes: notes,
      tracksWeight: row['tracks_weight'] != false,
      targetWeight: targetWeight ?? _toInt(row['target_weight_kg']),
      isAssigned: isAssigned,
      sourceId: row['source_id']?.toString(),
      equipment: row['equipment']?.toString(),
      level: row['level']?.toString(),
      category: row['category']?.toString(),
      primaryMuscles: _toStringList(row['primary_muscles']),
      secondaryMuscles: _toStringList(row['secondary_muscles']),
      instructions: instructions,
      imageUrls: _toStringList(row['image_urls']),
    );
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }
    return const [];
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
        .watch(appDataRepositoryProvider)
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
        .watch(appDataRepositoryProvider)
        .saveExerciseLogs(exercise, completed);
  }
}
