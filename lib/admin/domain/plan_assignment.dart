import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/workout_plan.dart';

/// Turns a plan template plus the library into the snapshot stored on an
/// assignment.
///
/// Pulled out of the repository so the two things that can go wrong here
/// are testable: the order must follow the plan, because it is what the
/// member's unlock walks through, and an exercise deleted from the
/// library since the plan was built must drop out rather than be
/// assigned as a blank.
List<PlanExercise> snapshotExercises({
  required WorkoutPlan plan,
  required List<Exercise> library,
}) {
  final byId = {for (final exercise in library) exercise.id: exercise};

  return [
    for (final id in plan.exerciseRefs)
      if (byId[id] != null) PlanExercise.snapshot(byId[id]!),
  ];
}
