import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';

/// Where an assigned plan stands for the member it belongs to.
enum AssignedPlanStatus {
  active,
  completed,
  cancelled;

  static AssignedPlanStatus fromName(Object? value) {
    final name = value?.toString();
    return AssignedPlanStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => AssignedPlanStatus.active,
    );
  }

  /// The transitions the app allows, checked in one place so no screen can
  /// invent its own.
  bool canMoveTo(AssignedPlanStatus next) {
    if (this == next) return true;
    switch (this) {
      case AssignedPlanStatus.active:
        return true;
      case AssignedPlanStatus.completed:
        return next == AssignedPlanStatus.active;
      case AssignedPlanStatus.cancelled:
        return false;
    }
  }
}

/// One exercise as it was at the moment the plan was assigned.
///
/// This is a copy, not a reference. If it referenced the library, an admin
/// renaming "Squat" would retroactively rewrite every member's completed
/// history and break every report — which is exactly what the guide forbids.
class AssignedExercise {
  const AssignedExercise({
    required this.order,
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.targetWeight,
    required this.tracksWeight,
    required this.notes,
    this.sourceId,
    this.equipment,
    this.level,
    this.category,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.imageUrls = const [],
  });

  final int order;
  final String exerciseId;
  final String name;
  final String description;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;
  final int targetWeight;
  final bool tracksWeight;
  final String notes;
  final String? sourceId;
  final String? equipment;
  final String? level;
  final String? category;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<String> imageUrls;

  factory AssignedExercise.fromMap(Map<String, dynamic> map, {int order = 0}) {
    final instructions = Val.toTextList(map['instructions']);
    final description = Val.toText(map['description']);
    return AssignedExercise(
      order: Val.toInt(map['order'], fallback: order),
      exerciseId: Val.toText(map['exerciseId']),
      name: Val.toText(map['name'], fallback: 'Exercise'),
      description: description.isNotEmpty
          ? description
          : instructions.take(2).join(' '),
      muscleGroup: Val.toText(map['muscleGroup'], fallback: 'Full Body'),
      sets: Val.toInt(map['sets'], fallback: 3),
      reps: Val.toText(map['reps'], fallback: '10'),
      restSeconds: Val.toInt(map['restSeconds'], fallback: 60),
      targetWeight: Val.toInt(map['targetWeight']),
      tracksWeight: Val.toBool(map['tracksWeight'], fallback: true),
      notes: Val.toText(map['notes']),
      sourceId: Val.toNullableText(map['sourceId']),
      equipment: Val.toNullableText(map['equipment']),
      level: Val.toNullableText(map['level']),
      category: Val.toNullableText(map['category']),
      primaryMuscles: Val.toTextList(map['primaryMuscles']),
      secondaryMuscles: Val.toTextList(map['secondaryMuscles']),
      instructions: instructions,
      imageUrls: Val.toTextList(map['imageUrls']),
    );
  }

  /// Takes the snapshot. Called once, at assignment time.
  factory AssignedExercise.snapshot(Exercise exercise, int order) {
    return AssignedExercise(
      order: order,
      exerciseId: exercise.id,
      name: exercise.name,
      description: exercise.description,
      muscleGroup: exercise.muscleGroup,
      sets: exercise.sets <= 0 ? 3 : exercise.sets,
      reps: exercise.reps.isEmpty ? '10' : exercise.reps,
      restSeconds: exercise.restSeconds <= 0 ? 60 : exercise.restSeconds,
      targetWeight: exercise.tracksWeight ? exercise.targetWeight : 0,
      tracksWeight: exercise.tracksWeight,
      notes: exercise.notes.isEmpty
          ? 'Controlled reps. Leave one rep in reserve.'
          : exercise.notes,
      sourceId: exercise.sourceId,
      equipment: exercise.equipment,
      level: exercise.level,
      category: exercise.category,
      primaryMuscles: exercise.primaryMuscles,
      secondaryMuscles: exercise.secondaryMuscles,
      instructions: exercise.instructions,
      imageUrls: exercise.imageUrls,
    );
  }

  Map<String, Object?> toMap() => {
    'order': order,
    'exerciseId': exerciseId,
    'name': name,
    'description': description,
    'muscleGroup': muscleGroup,
    'sets': sets,
    'reps': reps,
    'restSeconds': restSeconds,
    'targetWeight': targetWeight,
    'tracksWeight': tracksWeight,
    'notes': notes,
    'sourceId': sourceId,
    'equipment': equipment,
    'level': level,
    'category': category,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'instructions': instructions,
    'imageUrls': imageUrls,
  };

  /// Maps back to the UI model the screens already use.
  ///
  /// [planId] becomes the exercise's `workoutExerciseId` combined with the
  /// order, which is what logging and notes key on.
  Exercise toExercise({
    required String planId,
    required int completedSetCount,
    required bool isLocked,
  }) {
    return Exercise(
      id: exerciseId,
      workoutExerciseId: '$planId:$order',
      name: name,
      description: description,
      muscleGroup: muscleGroup,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      icon: muscleGroup.toLowerCase(),
      notes: notes,
      tracksWeight: tracksWeight,
      targetWeight: targetWeight,
      isAssigned: true,
      isLocked: isLocked,
      sourceId: sourceId,
      equipment: equipment,
      level: level,
      category: category,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      instructions: instructions,
      imageUrls: imageUrls,
      completedSetCount: completedSetCount,
    );
  }
}

/// A plan assigned to one member, with the exercises frozen at assignment time
/// and a [currentIndex] that drives the sequential unlock.
class AssignedPlan {
  const AssignedPlan({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.title,
    required this.focus,
    required this.level,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.scheduledDate,
    required this.exercises,
    required this.currentIndex,
    required this.status,
    required this.assignedAt,
    this.assignedBy,
  });

  final String id;
  final String memberId;
  final String planId;
  final String title;
  final String focus;
  final String level;
  final int durationMinutes;
  final int estimatedCalories;

  /// `yyyy-MM-dd`. The day this plan is meant for.
  final String scheduledDate;
  final List<AssignedExercise> exercises;

  /// Everything at an index below this is done or skipped; everything above it
  /// is locked. Persisted, so unlock progress survives a restart and does not
  /// reset daily.
  final int currentIndex;
  final AssignedPlanStatus status;
  final DateTime assignedAt;
  final String? assignedBy;

  bool get isFinished =>
      status == AssignedPlanStatus.completed || currentIndex >= exercises.length;

  int get totalSets =>
      exercises.fold<int>(0, (total, exercise) => total + exercise.sets);

  /// An exercise is locked when its index is ahead of [currentIndex].
  bool isLockedAt(int index) => index > currentIndex;

  AssignedExercise? get currentExercise =>
      currentIndex >= 0 && currentIndex < exercises.length
      ? exercises[currentIndex]
      : null;

  factory AssignedPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawExercises = Val.toMapList(data['exercises']);
    final exercises = <AssignedExercise>[
      for (var i = 0; i < rawExercises.length; i++)
        AssignedExercise.fromMap(rawExercises[i], order: i),
    ]..sort((a, b) => a.order.compareTo(b.order));

    return AssignedPlan(
      id: doc.id,
      memberId: Val.toText(data['memberId']),
      planId: Val.toText(data['planId']),
      title: Val.toText(data['title'], fallback: 'Workout'),
      focus: Val.toText(data['focus'], fallback: 'Assigned Program'),
      level: Val.toText(data['level']),
      durationMinutes: Val.toInt(data['durationMinutes']),
      estimatedCalories: Val.toInt(data['estimatedCalories']),
      scheduledDate: Val.toText(
        data['scheduledDate'],
        fallback: Val.dayKey(Val.toDate(data['assignedAt'])),
      ),
      exercises: exercises,
      currentIndex: Val.toInt(data['currentIndex']).clamp(0, exercises.length),
      status: AssignedPlanStatus.fromName(data['status']),
      assignedAt: Val.toDate(data['assignedAt'] ?? data[BaseFields.createdAt]),
      assignedBy: Val.toNullableText(
        data['assignedBy'] ?? data[BaseFields.createdBy],
      ),
    );
  }

  Map<String, Object?> toFirestore() => {
    'memberId': memberId,
    'planId': planId,
    'title': title,
    'focus': focus,
    'level': level,
    'durationMinutes': durationMinutes,
    'estimatedCalories': estimatedCalories,
    'scheduledDate': scheduledDate,
    'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    'currentIndex': currentIndex,
    'status': status.name,
    'assignedBy': assignedBy,
  };

  /// Maps to the UI model the screens already render.
  WorkoutPlan toWorkoutPlan({Map<int, int> completedSetsByOrder = const {}}) {
    final uiExercises = <Exercise>[
      for (var i = 0; i < exercises.length; i++)
        exercises[i].toExercise(
          planId: id,
          completedSetCount: (completedSetsByOrder[exercises[i].order] ?? 0)
              .clamp(0, exercises[i].sets),
          isLocked: isLockedAt(i),
        ),
    ];

    final total = totalSets;
    final done = uiExercises.fold<int>(
      0,
      (total, exercise) => total + exercise.completedSetCount,
    );

    return WorkoutPlan(
      id: id,
      name: title,
      focus: focus,
      durationMinutes: durationMinutes,
      estimatedCalories: estimatedCalories,
      level: level,
      completionPercent: total <= 0 ? 0 : (done / total).clamp(0.0, 1.0),
      exercises: uiExercises,
      currentIndex: currentIndex,
      status: status.name,
    );
  }
}
