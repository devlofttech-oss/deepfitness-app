import 'dart:typed_data';

import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/utils/image_resizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(firebaseStorageProvider)),
);

/// Cloud Storage uploads. Every image is resized here rather than at the
/// call site, so no screen can skip the step.
class StorageService {
  const StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Uploads an image for an exercise or an event.
  ///
  /// Same resize as a profile photo: the storage rules cap these at ten
  /// megabytes, and a photo straight off a phone can exceed that.
  Future<String> uploadContentImage({
    required String folder,
    required String id,
    required Uint8List bytes,
  }) async {
    try {
      final resized = await resizeForUpload(bytes);
      final ref = _storage.ref(
        '$folder/$id/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putData(resized, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw RepositoryFailure.fromFirestore(error);
    }
  }

  /// Uploads a member's profile photo and returns its download URL.
  ///
  /// The path matches the storage rules, which allow a member to write
  /// only under their own uid.
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    try {
      final resized = await resizeForUpload(bytes);
      final ref = _storage.ref('members/$uid/profile/avatar.jpg');
      await ref.putData(
        resized,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw RepositoryFailure.fromFirestore(error);
    }
  }
}
