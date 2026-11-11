import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/models/base_fields.dart';

/// Where a class video is hosted. The file itself is never uploaded: the
/// app stores the provider and the id and builds the embed URL.
enum VideoProvider {
  youtube,
  vimeo;

  static VideoProvider fromName(Object? value) {
    return VideoProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => VideoProvider.youtube,
    );
  }
}

/// An on-demand class video.
class GroupClass {
  const GroupClass({
    required this.base,
    required this.title,
    this.description = '',
    this.videoProvider = VideoProvider.youtube,
    this.videoId = '',
    this.thumbnailUrl,
    this.durationMins = 0,
  });

  factory GroupClass.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return GroupClass(
      base: BaseFields.fromMap(snapshot.id, data),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      videoProvider: VideoProvider.fromName(data['videoProvider']),
      videoId: (data['videoId'] as String?) ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationMins: (data['durationMins'] as num?)?.toInt() ?? 0,
    );
  }

  final BaseFields base;
  final String title;
  final String description;
  final VideoProvider videoProvider;
  final String videoId;
  final String? thumbnailUrl;
  final int durationMins;

  String get id => base.id;

  bool get hasVideo => videoId.isNotEmpty;

  /// The URL the in-app player loads.
  ///
  /// Built here rather than stored, so a change of embed parameters does
  /// not mean rewriting every document. `playsinline` matters on iOS:
  /// without it the video takes over the screen, which is exactly the
  /// jump out of the app the document says to avoid.
  String get embedUrl => switch (videoProvider) {
    VideoProvider.youtube =>
      'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0',
    VideoProvider.vimeo =>
      'https://player.vimeo.com/video/$videoId?playsinline=1',
  };
}
