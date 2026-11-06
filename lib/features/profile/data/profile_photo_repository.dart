import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>(
  (ref) => ProfilePhotoRepository(ref.watch(appFirebaseProvider)),
);

/// Uploads a member's profile photo, resized before it leaves the device.
///
/// The resize is not cosmetic: a modern phone camera produces 4–8 MB images,
/// the storage rules cap an avatar at 5 MB, and a member on gym wifi should
/// not be made to upload a 12-megapixel photo to fill a 96-pixel circle.
class ProfilePhotoRepository {
  const ProfilePhotoRepository(this._firebase);

  final AppFirebase _firebase;

  /// Long enough for a retina avatar, small enough to upload on bad wifi.
  static const double _maxDimension = 1024;
  static const int _quality = 85;

  /// Picks an image and returns it already scaled down.
  ///
  /// Returns null when the member backs out of the picker, which is not an
  /// error and should not raise one.
  Future<XFile?> pick({required ImageSource source}) {
    return guard(() async {
      return ImagePicker().pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
    }, whileDoing: 'opening your photos');
  }

  /// Uploads [file] and writes the download URL onto the member document.
  ///
  /// Returns the URL so the caller can show it without a round trip.
  Future<String> upload(XFile file) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final bytes = await file.readAsBytes();

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        // The storage rules would reject it anyway; failing here says why.
        throw const RepositoryFailure(
          FailureKind.invalid,
          'That photo is too large even after resizing. Try another one.',
        );
      }

      // One object per member, overwritten: nobody needs a history of
      // somebody's old profile pictures.
      final ref = _firebase.storage.ref('members/$uid/avatar/profile.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .update({'photoUrl': url, ...BaseFields.onUpdate()});

      return url;
    }, whileDoing: 'uploading your photo', timeout: const Duration(seconds: 60));
  }

  /// Clears the photo. The object is left in place; the rules allow it to be
  /// overwritten, and a dangling file is cheaper than a failed delete.
  Future<void> remove() {
    return guard(() async {
      final uid = _firebase.requireUserId();
      await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .update({'photoUrl': null, ...BaseFields.onUpdate()});
    }, whileDoing: 'removing your photo');
  }
}
