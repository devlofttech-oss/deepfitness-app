import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/exercise.dart';

/// Where an assignment stands.
enum AssignedPlanStatus {
  active,
  completed,
  cancelled;

  static AssignedPlanStatus fromName(Object? value) {
    return AssignedPlanStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AssignedPlanStatus.active,
    );
  }
}

/// How a member left an exercise behind.
enum ExerciseOutcome { pending, completed, skipped }

/// One exercise as it was at the moment the plan was assigned.
///
/// This is a copy, not a reference. An admin editing "Squat" in the library
/// must not retroactively change what a member already did.
class PlanExercise {
  const PlanExercise({
    required this.exerciseId,
    required this.name,
    this.description = '',
    this.muscleGroup = '',
    this.photoUrl,
    this.sets = 3,
    this.reps = 10,
  });

  factory PlanExercise.fromMap(Map<String, dynamic> data) {
    return PlanExercise(
      exerciseId: (data['exerciseId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      muscleGroup: (data['muscleGroup'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      sets: (data['sets'] as num?)?.toInt() ?? 3,
      reps: (data['reps'] as num?)?.toInt() ?? 10,
    );
  }

  /// Takes the snapshot from a library exercise at assignment time.
  factory PlanExercise.snapshot(Exercise exercise) {
    return PlanExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      description: exercise.description,
      muscleGroup: exercise.muscleGroup,
      photoUrl: exercise.photoUrls.isEmpty ? null : exercise.photoUrls.first,
      sets: exercise.defaultSets,
      reps: exercise.defaultReps,
    );
  }

  final String exerciseId;
  final String name;
  final String description;
  final String muscleGroup;
  final String? photoUrl;
  final int sets;
  final int reps;

  Map<String, Object?> toMap() => {
    'exerciseId': exerciseId,
    'name': name,
    'description': description,
    'muscleGroup': muscleGroup,
    'photoUrl': photoUrl,
    'sets': sets,
    'reps': reps,
  };
}

/// A plan assigned to one member: the snapshot, and how far through it
/// they are.
class AssignedPlan {
  const AssignedPlan({
    required this.base,
    required this.memberId,
    required this.planId,
    required this.title,
    required this.exercises,
    required this.currentIndex,
    required this.status,
    this.assignedAt,
  });

  factory AssignedPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final raw = data['exercises'];
    return AssignedPlan(
      base: BaseFields.fromMap(snapshot.id, data),
      memberId: (data['memberId'] as String?) ?? '',
      planId: (data['planId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      exercises: raw is Iterable
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(PlanExercise.fromMap)
                .toList(growable: false)
          : const [],
      currentIndex: (data['currentIndex'] as num?)?.toInt() ?? 0,
      status: AssignedPlanStatus.fromName(data['status']),
      assignedAt: readTimestamp(data['assignedAt']),
    );
  }

  final BaseFields base;
  final String memberId;
  final String planId;
  final String title;
  final List<PlanExercise> exercises;

  /// How far the unlock has advanced. Everything below it is done or
  /// skipped; the exercise at it is the one to do now.
  final int currentIndex;

  final AssignedPlanStatus status;
  final DateTime? assignedAt;

  String get id => base.id;

  bool get isEmpty => exercises.isEmpty;

  bool get isComplete =>
      status == AssignedPlanStatus.completed ||
      (exercises.isNotEmpty && currentIndex >= exercises.length);

  /// The exercise the member should do now, or null once the plan is done.
  PlanExercise? get currentExercise =>
      isComplete || isEmpty ? null : exercises[currentIndex];

  /// Whether the exercise at [index] is still locked.
  ///
  /// This is the whole unlock rule: an exercise opens only when every one
  /// before it has been completed or skipped. It is a comparison against
  /// stored progress, not a daily reset, so it survives closing the app.
  bool isLocked(int index) => index > currentIndex;

  /// How the member left the exercise at [index].
  ///
  /// The document stores progress as a single index, so anything below it
  /// is finished; whether it was completed or skipped lives in the
  /// completion log, not here.
  ExerciseOutcome outcomeAt(int index) =>
      index < currentIndex ? ExerciseOutcome.completed : ExerciseOutcome.pending;

  /// Fraction of the plan behind the member, for a progress indicator.
  double get progress {
    if (exercises.isEmpty) return 0;
    final done = currentIndex.clamp(0, exercises.length);
    return done / exercises.length;
  }

  /// The fields written when the unlock advances.
  ///
  /// Only these three keys change, which is exactly what the security rule
  /// on `assigned_plans` permits a member to write.
  Map<String, Object?> advanceUpdate() {
    final next = currentIndex + 1;
    return {
      'currentIndex': next,
      'status': next >= exercises.length
          ? AssignedPlanStatus.completed.name
          : AssignedPlanStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
