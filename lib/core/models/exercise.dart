import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// An entry in the admin-managed exercise library.
///
/// This is the template. Assigning a plan copies the fields a member needs
/// onto the assignment, so an admin renaming an exercise later does not
/// rewrite anyone's completed history.
class Exercise {
  const Exercise({
    required this.base,
    required this.name,
    this.description = '',
    this.muscleGroup = '',
    this.photoUrls = const [],
    this.videoUrl,
    this.posterUrl,
    this.defaultSets = 3,
    this.defaultReps = 10,
  });

  factory Exercise.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return Exercise(
      base: BaseFields.fromMap(snapshot.id, data),
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      muscleGroup: (data['muscleGroup'] as String?) ?? '',
      photoUrls: readStringList(data['photoUrls']),
      videoUrl: data['videoUrl'] as String?,
      posterUrl: data['posterUrl'] as String?,
      defaultSets: (data['defaultSets'] as num?)?.toInt() ?? 3,
      defaultReps: (data['defaultReps'] as num?)?.toInt() ?? 10,
    );
  }

  final BaseFields base;
  final String name;
  final String description;
  final String muscleGroup;
  final List<String> photoUrls;

  /// The looping demonstration, where the exercise came from the animation
  /// pack. Hosted on the CDN rather than Firebase Storage, so the rules in
  /// `storage.rules` do not govern it.
  final String? videoUrl;

  /// A still from [videoUrl], the frame worth showing before anything plays.
  final String? posterUrl;

  final int defaultSets;
  final int defaultReps;

  String get id => base.id;

  /// The still to show.
  ///
  /// A hand-uploaded photo wins over the pack's poster: uploading one is a
  /// deliberate act by a trainer, and the poster is only ever a default.
  String? get stillUrl => photoUrls.isEmpty ? posterUrl : photoUrls.first;

  Map<String, Object?> toFirestore() => {
    'name': name,
    'description': description,
    'muscleGroup': muscleGroup,
    'photoUrls': photoUrls,
    'videoUrl': videoUrl,
    'posterUrl': posterUrl,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
  };
}
