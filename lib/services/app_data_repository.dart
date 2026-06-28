import 'package:deepfitness/services/supabase_service.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(ref.watch(supabaseServiceProvider)),
);

final currentUserProvider = FutureProvider<AppUser>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchCurrentUser(),
);

final workoutProvider = FutureProvider<WorkoutPlan>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchTodayWorkout(),
);

final nutritionProvider = FutureProvider<NutritionPlan>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchNutritionPlan(),
);

final progressProvider = FutureProvider<MemberProgress>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchProgress(),
);

final appSettingsProvider = FutureProvider<AppSettings>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchSettings(),
);

final membersProvider = FutureProvider<List<MemberSummary>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchMembers(),
);

final exerciseLibraryProvider = FutureProvider<List<Exercise>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchExerciseLibrary(),
);

final trainerStatsProvider = FutureProvider<TrainerDashboardStats>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchTrainerStats(),
);

final savedWorkoutPlansProvider = FutureProvider<List<WorkoutPlan>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchSavedWorkoutPlans(),
);

final savedDietPlansProvider = FutureProvider<List<NutritionPlan>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchSavedDietPlans(),
);

final mealTemplatesProvider = FutureProvider<List<DietMeal>>(
  (ref) => ref.watch(appDataRepositoryProvider).fetchMealTemplates(),
);

final selectedExerciseProvider =
    NotifierProvider<SelectedExerciseController, Exercise?>(
      SelectedExerciseController.new,
    );

class SelectedExerciseController extends Notifier<Exercise?> {
  @override
  Exercise? build() => null;

  void select(Exercise exercise) => state = exercise;
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

    if (row == null) throw StateError('Your profile is not ready yet.');

    final role = row['role'] == 'trainer' ? UserRole.trainer : UserRole.member;
    String? trainerName;
    String? goal;
    double? heightCm;

    if (role == UserRole.member) {
      final memberRow = await _supabaseService.client
          .from('members')
          .select('goal,height_cm,age,trainers(name)')
          .eq('id', authUser.id)
          .maybeSingle();
      goal = memberRow?['goal']?.toString();
      heightCm = _toNullableDouble(memberRow?['height_cm']);
      final age = _toNullableInt(memberRow?['age']);
      final trainer = memberRow?['trainers'];
      if (trainer is Map) trainerName = trainer['name']?.toString();
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
          'id,sets,reps,rest_seconds,trainer_notes,sort_order,exercises(id,source_id,name,description,muscle_group,rest_seconds,equipment,level,category,primary_muscles,secondary_muscles,instructions,image_urls)',
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
        notes: (row['trainer_notes'] ?? '').toString(),
      );
    }).toList();

    final workoutExerciseIds = exercises
        .map((exercise) => exercise.workoutExerciseId)
        .whereType<String>()
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
      completionPercent: await _workoutCompletion(
        userId,
        workoutExerciseIds,
        totalSets,
      ),
      exercises: exercises,
    );
  }

  Future<NutritionPlan> fetchNutritionPlan({String? memberId}) async {
    _requireClient();
    final userId = memberId ?? _authUserId;
    if (userId == null) throw StateError('You are not logged in.');
    final waterGoal = await _fetchWaterGoal(userId);
    final waterLiters = await _fetchWaterLitersForDate(userId, DateTime.now());

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

    final meals = mealRows.map<DietMeal>((row) {
      return DietMeal(
        name: row['name'].toString(),
        time: _formatTime(row['meal_time']?.toString()),
        description: (row['description'] ?? '').toString(),
        calories: _toInt(row['calories']),
        icon: row['name'].toString().toLowerCase(),
      );
    }).toList();

    final consumed = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final goal = _toInt(plan['daily_calories']);

    return NutritionPlan(
      calories: consumed,
      goalCalories: goal,
      protein: _toInt(plan['protein_g']),
      carbs: _toInt(plan['carbs_g']),
      fats: _toInt(plan['fats_g']),
      caloriesLeft: (goal - consumed).clamp(0, goal),
      waterLiters: waterLiters,
      waterGoalLiters: waterGoal,
      meals: meals,
    );
  }

  Future<MemberProgress> fetchProgress({String? memberId}) async {
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

    final logs = await _supabaseService.client
        .from('exercise_logs')
        .select('weight,reps,completed,logged_at,exercises(name,muscle_group)')
        .eq('member_id', userId)
        .order('logged_at', ascending: false);

    final now = DateTime.now();
    final completedLogs = logs.where((row) => row['completed'] != false);
    final workoutDatesThisMonth = <String>{};
    for (final row in completedLogs) {
      final loggedAt = DateTime.tryParse(row['logged_at'].toString());
      if (loggedAt != null &&
          loggedAt.year == now.year &&
          loggedAt.month == now.month) {
        workoutDatesThisMonth.add(loggedAt.toIso8601String().substring(0, 10));
      }
    }

    final personalBests = <String, int>{};
    final muscleCounts = <String, int>{};
    for (final row in completedLogs) {
      final exercise = row['exercises'];
      if (exercise is! Map) continue;
      final name = exercise['name'].toString();
      final muscle = exercise['muscle_group'].toString();
      final weight = _toInt(row['weight']);
      if (!personalBests.containsKey(name) || weight > personalBests[name]!) {
        personalBests[name] = weight;
      }
      muscleCounts[muscle] = (muscleCounts[muscle] ?? 0) + 1;
    }

    return MemberProgress(
      currentWeight: currentWeight,
      weightDelta: double.parse(
        (currentWeight - previousWeight).toStringAsFixed(1),
      ),
      workoutsThisMonth: workoutDatesThisMonth.length,
      goalCompletion: await _latestWorkoutCompletion(userId),
      dayStreak: _dayStreakFromLogs(logs),
      muscleProgress: muscleCounts.map(
        (key, value) => MapEntry(key, (value * 7).clamp(8, 28)),
      ),
      personalBests: Map.fromEntries(personalBests.entries.take(3)),
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

  Future<void> addWater(double liters) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _supabaseService.client.from('water_logs').upsert({
      'member_id': _authUserId,
      'logged_date': today,
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
    final rows = await _supabaseService.client
        .from('exercise_logs')
        .select()
        .eq('member_id', _authUserId!)
        .eq('exercise_id', exercise.id)
        .order('set_number');
    if (rows.isEmpty) return _defaultLogs(exercise);
    return rows.map<ExerciseLog>((row) {
      return ExerciseLog(
        id: row['id'].toString(),
        setNumber: _toInt(row['set_number']),
        weight: _toInt(row['weight']),
        reps: _toInt(row['reps']),
        completed: row['completed'] != false,
      );
    }).toList();
  }

  Future<void> saveExerciseLogs(
    Exercise exercise,
    List<ExerciseLog> logs,
  ) async {
    _requireClient();
    if (_authUserId == null) throw StateError('You are not logged in.');
    final payload = logs.map((log) {
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
    final plan = await _supabaseService.client
        .from('workout_plans')
        .insert({
          'trainer_id': _authUserId,
          'member_id': memberId,
          'name': name,
          'focus': focus,
        })
        .select('id')
        .single();
    final day = await _supabaseService.client
        .from('workout_days')
        .insert({
          'workout_plan_id': plan['id'],
          'scheduled_date': DateTime.now().toIso8601String().substring(0, 10),
          'title': name,
          'duration_minutes': exercises.length * 12,
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
        ExerciseLog(setNumber: i, weight: 0, reps: reps),
    ];
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
          'id,sets,reps,rest_seconds,trainer_notes,sort_order,exercises(id,source_id,name,description,muscle_group,rest_seconds,equipment,level,category,primary_muscles,secondary_muscles,instructions,image_urls)',
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

  void addExtraSet() {
    final current = state.value ?? const <ExerciseLog>[];
    final last = current.isEmpty ? 0 : current.last.setNumber;
    state = AsyncData([
      ...current,
      ExerciseLog(setNumber: last + 1, weight: 0, reps: 0),
    ]);
  }

  Future<void> save(Exercise exercise) async {
    final current = state.value ?? const <ExerciseLog>[];
    await ref
        .watch(appDataRepositoryProvider)
        .saveExerciseLogs(exercise, current);
  }
}
