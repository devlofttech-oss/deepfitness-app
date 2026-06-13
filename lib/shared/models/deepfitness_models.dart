enum UserRole { member, trainer }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.trainerName,
    this.goal,
    this.heightCm,
    this.age,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? trainerName;
  final String? goal;
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
    this.workoutExerciseId,
    this.isAssigned = true,
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
  final String? workoutExerciseId;
  final bool isAssigned;
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.focus,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.level,
    required this.exercises,
  });

  final String id;
  final String name;
  final String focus;
  final int durationMinutes;
  final int estimatedCalories;
  final String level;
  final List<Exercise> exercises;
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
  });

  final String name;
  final String time;
  final String description;
  final int calories;
  final String icon;
}

class NutritionPlan {
  const NutritionPlan({
    required this.calories,
    required this.goalCalories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.caloriesLeft,
    required this.meals,
  });

  final int calories;
  final int goalCalories;
  final int protein;
  final int carbs;
  final int fats;
  final int caloriesLeft;
  final List<DietMeal> meals;
}

class MemberProgress {
  const MemberProgress({
    required this.currentWeight,
    required this.weightDelta,
    required this.workoutsThisMonth,
    required this.goalCompletion,
    required this.muscleProgress,
    required this.personalBests,
  });

  final double currentWeight;
  final double weightDelta;
  final int workoutsThisMonth;
  final double goalCompletion;
  final Map<String, int> muscleProgress;
  final Map<String, int> personalBests;
}
