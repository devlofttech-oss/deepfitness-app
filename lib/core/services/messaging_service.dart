import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/repositories/base_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => MessagingService(
    ref.watch(firebaseMessagingProvider),
    FirebaseFirestore.instance,
  ),
);

/// Cloud Messaging: permission, and keeping `fcmTokens[]` on the member
/// document in step with the devices actually signed in.
class MessagingService {
  const MessagingService(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Asks for notification permission and returns whether it was granted.
  ///
  /// Android below 13 and a previously granted iOS prompt both return
  /// without showing anything, so this is safe to call on every sign-in.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Adds this device's token to the member document, on sign-in.
  ///
  /// `arrayUnion` means a second sign-in on the same device does not
  /// duplicate the token, and a member signed in on two devices keeps both.
  Future<void> registerToken(String memberId) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection(Collections.members).doc(memberId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes this device's token, on sign-out.
  ///
  /// Done before the sign-out itself, while the rules still allow the write;
  /// afterwards the member can no longer touch their own document.
  Future<void> unregisterToken(String memberId) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.collection(Collections.members).doc(memberId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fires when Firebase rotates the token while the app is running.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
