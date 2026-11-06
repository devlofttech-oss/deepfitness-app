import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';

enum UserRole {
  member,
  trainer,
  admin;

  /// An admin can do everything a trainer can, and more besides. Anywhere
  /// that gates on "staff" means this, not `== trainer`.
  bool get isStaff => this == trainer || this == admin;

  bool get isAdmin => this == admin;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.phone,
    this.avatarUrl,
    this.trainerName,
    this.goal,
    this.gender,
    this.heightCm,
    this.age,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  final String? phone;
  final String? avatarUrl;
  final String? trainerName;
  final String? goal;
  final String? gender;
  final double? heightCm;
  final int? age;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.icon,
    required this.notes,
    required this.tracksWeight,
    required this.targetWeight,
    this.workoutExerciseId,
    this.isAssigned = true,
    this.isLocked = false,
    this.isSkipped = false,
    this.skipReason,
    this.sourceId,
    this.equipment,
    this.level,
    this.category,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.imageUrls = const [],
    this.completedSetCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;
  final String icon;
  final String notes;
  final bool tracksWeight;
  final int targetWeight;
  final String? workoutExerciseId;
  final bool isAssigned;

  /// True when this exercise sits ahead of the plan's `currentIndex`, so the
  /// member cannot open it yet.
  final bool isLocked;

  /// True when the member moved past this exercise without completing it.
  final bool isSkipped;
  final String? skipReason;
  final String? sourceId;
  final String? equipment;
  final String? level;
  final String? category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<String> imageUrls;
  final int completedSetCount;

  bool get isCompleted => completedSetCount >= sets && sets > 0;

  /// Done with, one way or the other — used by the plan screen to decide
  /// whether to show a tick or a skip badge.
  bool get isSettled => isCompleted || isSkipped;

  /// Reads one document from the admin-managed `exercises` library.
  factory Exercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final instructions = Val.toTextList(data['instructions']);
    final description = Val.toText(data['description']);
    final muscleGroup = Val.toText(data['muscleGroup'], fallback: 'Full Body');
    return Exercise(
      id: doc.id,
      name: Val.toText(data['name'], fallback: 'Exercise'),
      description: description.isNotEmpty
          ? description
          : instructions.take(2).join(' '),
      muscleGroup: muscleGroup,
      sets: Val.toInt(data['defaultSets'], fallback: 3),
      reps: Val.toText(data['defaultReps'], fallback: '10'),
      restSeconds: Val.toInt(data['restSeconds'], fallback: 60),
      icon: muscleGroup.toLowerCase(),
      notes: '',
      tracksWeight: Val.toBool(data['tracksWeight'], fallback: true),
      targetWeight: Val.toInt(data['targetWeight']),
      isAssigned: false,
      sourceId: Val.toNullableText(data['sourceId']),
      equipment: Val.toNullableText(data['equipment']),
      level: Val.toNullableText(data['level']),
      category: Val.toNullableText(data['category']),
      primaryMuscles: Val.toTextList(data['primaryMuscles']),
      secondaryMuscles: Val.toTextList(data['secondaryMuscles']),
      instructions: instructions,
      imageUrls: Val.toTextList(data['imageUrls']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'name': name,
    'description': description,
    'muscleGroup': muscleGroup,
    'defaultSets': sets,
    'defaultReps': reps,
    'restSeconds': restSeconds,
    'tracksWeight': tracksWeight,
    'targetWeight': targetWeight,
    'sourceId': sourceId,
    'equipment': equipment,
    'level': level,
    'category': category,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'instructions': instructions,
    'imageUrls': imageUrls,
  };

  Exercise copyWith({
    int? completedSetCount,
    bool? isLocked,
    bool? isSkipped,
    String? skipReason,
    int? sets,
    String? reps,
    int? restSeconds,
    int? targetWeight,
    String? notes,
  }) {
    return Exercise(
      id: id,
      name: name,
      description: description,
      muscleGroup: muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      icon: icon,
      notes: notes ?? this.notes,
      tracksWeight: tracksWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      workoutExerciseId: workoutExerciseId,
      isAssigned: isAssigned,
      isLocked: isLocked ?? this.isLocked,
      isSkipped: isSkipped ?? this.isSkipped,
      skipReason: skipReason ?? this.skipReason,
      sourceId: sourceId,
      equipment: equipment,
      level: level,
      category: category,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      instructions: instructions,
      imageUrls: imageUrls,
      completedSetCount: completedSetCount ?? this.completedSetCount,
    );
  }
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.focus,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.level,
    required this.completionPercent,
    required this.exercises,
    this.currentIndex = 0,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String focus;
  final int durationMinutes;
  final int estimatedCalories;
  final String level;
  final double completionPercent;
  final List<Exercise> exercises;

  /// Position of the exercise the member may work on now. Everything above it
  /// is locked; everything below it is done or skipped.
  final int currentIndex;
  final String status;

  bool get isEmpty => id == 'empty' || exercises.isEmpty;

  bool get isFinished =>
      exercises.isNotEmpty && currentIndex >= exercises.length;

  /// The exercise the member should be on, or null once the plan is finished.
  Exercise? get currentExercise =>
      currentIndex >= 0 && currentIndex < exercises.length
      ? exercises[currentIndex]
      : null;

  int indexOf(Exercise exercise) {
    final key = exercise.workoutExerciseId;
    if (key != null) {
      final match = exercises.indexWhere(
        (item) => item.workoutExerciseId == key,
      );
      if (match >= 0) return match;
    }
    return exercises.indexWhere((item) => item.id == exercise.id);
  }

  bool isUnlocked(Exercise exercise) {
    final index = indexOf(exercise);
    return index >= 0 && index <= currentIndex;
  }
}

class ExerciseLog {
  const ExerciseLog({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.completed = true,
    this.id,
  });

  final String? id;
  final int setNumber;
  final int weight;
  final int reps;
  final bool completed;
}

class AppSettings {
  const AppSettings({
    required this.notificationsEnabled,
    required this.preferredUnit,
  });

  final bool notificationsEnabled;
  final String preferredUnit;
}

class MemberSummary {
  const MemberSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.goal,
    required this.heightCm,
    required this.currentWeight,
    required this.trainerName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String goal;
  final double heightCm;
  final double currentWeight;
  final String trainerName;
}

class CreatedMemberInvite {
  const CreatedMemberInvite({required this.member, required this.inviteText});

  final MemberSummary member;
  final String inviteText;
}

class TrainerDashboardStats {
  const TrainerDashboardStats({
    required this.memberCount,
    required this.activePlanCount,
  });

  final int memberCount;
  final int activePlanCount;
}

class DietMeal {
  const DietMeal({
    required this.name,
    required this.time,
    required this.description,
    required this.calories,
    required this.icon,
    this.id,
    this.logged = false,
  });

  final String? id;
  final String name;
  final String time;
  final String description;
  final int calories;
  final String icon;
  final bool logged;
}

class NutritionPlan {
  const NutritionPlan({
    required this.calories,
    required this.goalCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.caloriesLeft,
    required this.waterLiters,
    required this.waterGoalLiters,
    required this.meals,
  });

  final int calories;
  final int goalCalories;
  final int protein;
  final int carbs;
  final int fats;
  final int caloriesLeft;
  final double waterLiters;
  final double waterGoalLiters;
  final List<DietMeal> meals;
}

class MemberProgress {
  const MemberProgress({
    required this.currentWeight,
    required this.weightDelta,
    required this.workoutsCompleted,
    required this.goalCompletion,
    required this.dayStreak,
    required this.muscleProgress,
    required this.personalBests,
    required this.assignedExercises,
    required this.completedExercises,
    required this.missedExercises,
    required this.adherence,
    this.gender,
  });

  final double currentWeight;
  final double weightDelta;
  final int workoutsCompleted;
  final double goalCompletion;
  final int dayStreak;
  final Map<String, int> muscleProgress;
  final Map<String, int> personalBests;
  final int assignedExercises;
  final int completedExercises;
  final int missedExercises;
  final double adherence;
  final String? gender;
}
