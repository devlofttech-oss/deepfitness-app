import 'dart:typed_data';

import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/storage_service.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

/// Saves the fields a member may change about themselves.
///
/// Nothing here can touch membership status or expiry: those are staff
/// owned, the rules reject them, and the model's update map leaves them out.
class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves the profile and refreshes the session so the new name and photo
  /// appear everywhere at once.
  Future<bool> save({
    required String name,
    String? phone,
    String? email,
    Uint8List? photoBytes,
  }) async {
    final uid = ref.read(authControllerProvider).value?.user?.uid;
    if (uid == null) return false;

    state = const AsyncLoading();

    try {
      // The photo goes up first: if the upload fails there is no point
      // writing a document that points at a file which does not exist.
      String? photoUrl;
      if (photoBytes != null) {
        photoUrl = await ref
            .read(storageServiceProvider)
            .uploadProfilePhoto(uid: uid, bytes: photoBytes);
      }

      await ref
          .read(memberRepositoryProvider)
          .updateProfile(
            uid: uid,
            name: name,
            phone: phone,
            email: email,
            photoUrl: photoUrl,
          );

      ref.invalidate(authControllerProvider);
      state = const AsyncData(null);
      return true;
    } on RepositoryFailure catch (failure, stackTrace) {
      state = AsyncError(failure, stackTrace);
      return false;
    }
  }
}
