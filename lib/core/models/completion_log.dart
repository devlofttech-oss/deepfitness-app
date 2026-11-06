import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/core/models/app_models.dart';

/// One set as it was actually performed.
class CompletedSet {
  const CompletedSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  final int setNumber;
  final int weight;
  final int reps;

  factory CompletedSet.fromMap(Map<String, dynamic> map) => CompletedSet(
    setNumber: Val.toInt(map['setNumber'], fallback: 1),
    weight: Val.toInt(map['weight']),
    reps: Val.toInt(map['reps']),
  );

  factory CompletedSet.fromLog(ExerciseLog log) => CompletedSet(
    setNumber: log.setNumber,
    weight: log.weight,
    reps: log.reps,
  );

  Map<String, Object?> toMap() => {
    'setNumber': setNumber,
    'weight': weight,
    'reps': reps,
  };

  ExerciseLog toExerciseLog() => ExerciseLog(
    setNumber: setNumber,
    weight: weight,
    reps: reps,
    completed: true,
  );
}

/// Append-only record of one exercise being completed or skipped.
///
/// The guide's "one log, many reports": completion rate, streaks, volume and
/// personal bests are all derived from this collection, so no report needs
/// storage of its own.
class CompletionLog {
  const CompletionLog({
    required this.id,
    required this.memberId,
    required this.assignedPlanId,
    required this.exerciseIndex,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.setsPlanned,
    required this.setsDone,
    required this.sets,
    required this.skipped,
    required this.completedAt,
    this.skipReason,
    this.tracksWeight = true,
  });

  final String id;
  final String memberId;
  final String assignedPlanId;

  /// Position within the assigned plan, so a log ties back to the exercise it
  /// came from even after the member is assigned the same plan again.
  final int exerciseIndex;
  final String exerciseId;

  /// Copied from the snapshot, not looked up — a later rename must not change
  /// what this log says was done.
  final String exerciseName;
  final String muscleGroup;
  final int setsPlanned;
  final int setsDone;
  final List<CompletedSet> sets;
  final bool skipped;
  final String? skipReason;
  final DateTime completedAt;
  final bool tracksWeight;

  /// Heaviest set in this log, for the personal-best report. Zero for
  /// bodyweight work.
  int get topWeight {
    if (!tracksWeight || sets.isEmpty) return 0;
    return sets.fold<int>(0, (best, set) => set.weight > best ? set.weight : best);
  }

  int get totalReps => sets.fold<int>(0, (total, set) => total + set.reps);

  int get volume =>
      sets.fold<int>(0, (total, set) => total + (set.weight * set.reps));

  factory CompletionLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompletionLog(
      id: doc.id,
      memberId: Val.toText(data['memberId']),
      assignedPlanId: Val.toText(data['assignedPlanId']),
      exerciseIndex: Val.toInt(data['exerciseIndex']),
      exerciseId: Val.toText(data['exerciseId']),
      exerciseName: Val.toText(data['exerciseName'], fallback: 'Exercise'),
      muscleGroup: Val.toText(data['muscleGroup'], fallback: 'Full Body'),
      setsPlanned: Val.toInt(data['setsPlanned']),
      setsDone: Val.toInt(data['setsDone']),
      sets: Val.toMapList(data['sets']).map(CompletedSet.fromMap).toList(),
      skipped: Val.toBool(data['skipped']),
      skipReason: Val.toNullableText(data['skipReason']),
      completedAt: Val.toDate(
        data['completedAt'] ?? data[BaseFields.createdAt],
      ),
      tracksWeight: Val.toBool(data['tracksWeight'], fallback: true),
    );
  }

  Map<String, Object?> toFirestore() => {
    'memberId': memberId,
    'assignedPlanId': assignedPlanId,
    'exerciseIndex': exerciseIndex,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'muscleGroup': muscleGroup,
    'setsPlanned': setsPlanned,
    'setsDone': setsDone,
    'sets': sets.map((set) => set.toMap()).toList(),
    'skipped': skipped,
    'skipReason': skipReason,
    'tracksWeight': tracksWeight,
    'topWeight': topWeight,
    'volume': volume,
    'completedAt': FieldValue.serverTimestamp(),
  };
}
