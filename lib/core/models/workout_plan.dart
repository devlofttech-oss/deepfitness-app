import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// A reusable plan template, built in the dashboard.
///
/// It holds ordered references into the exercise library. The snapshot onto
/// a member happens at assignment time, not here.
class WorkoutPlan {
  const WorkoutPlan({
    required this.base,
    required this.title,
    this.description = '',
    this.exerciseRefs = const [],
  });

  factory WorkoutPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return WorkoutPlan(
      base: BaseFields.fromMap(snapshot.id, data),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      exerciseRefs: readStringList(data['exerciseRefs']),
    );
  }

  final BaseFields base;
  final String title;
  final String description;

  /// Exercise ids, in the order the member works through them.
  final List<String> exerciseRefs;

  String get id => base.id;

  Map<String, Object?> toFirestore() => {
    'title': title,
    'description': description,
    'exerciseRefs': exerciseRefs,
  };
}
