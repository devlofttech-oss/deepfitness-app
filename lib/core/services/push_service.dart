import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref.watch(appFirebaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Keeps `members/{uid}.fcmTokens[]` in step with this device.
///
/// Registration is asynchronous: `register()` kicks it off and the id arrives
/// later on [FirebaseMessaging.onRegistered], so the token is written from the
/// stream rather than from a return value.
class PushService {
  PushService(this._firebase);

  final AppFirebase _firebase;

  StreamSubscription<String>? _registered;
  StreamSubscription<String>? _unregistered;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Called after sign-in. Failures never block sign-in — a member without
  /// push still has a working app.
  Future<void> start() async {
    try {
      if (!_firebase.isConfigured) return;

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      _registered ??= _messaging.onRegistered.listen(_saveToken);
      _unregistered ??= _messaging.onUnregistered.listen(_removeToken);

      await _messaging.register();
    } catch (_) {
      // Push is best-effort.
    }
  }

  /// Called before sign-out, so the next person on this device does not
  /// receive the previous member's notifications.
  Future<void> stop() async {
    try {
      if (!_firebase.isConfigured) return;
      await _messaging.unregister();
    } catch (_) {
      // A stale token is pruned server-side on the next send failure.
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _firebase.currentUserId;
    if (uid == null || token.isEmpty) return;
    try {
      await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .set({
            'fcmTokens': FieldValue.arrayUnion([token]),
            ...BaseFields.onUpdate(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Ignored for the same reason as above.
    }
  }

  Future<void> _removeToken(String token) async {
    final uid = _firebase.currentUserId;
    if (uid == null || token.isEmpty) return;
    try {
      await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
            ...BaseFields.onUpdate(),
          });
    } catch (_) {
      // Ignored for the same reason as above.
    }
  }

  void dispose() {
    _registered?.cancel();
    _unregistered?.cancel();
    _registered = null;
    _unregistered = null;
  }
}
