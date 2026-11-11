import 'dart:async';

import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/core/services/messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final notificationHandlerProvider = Provider<NotificationHandler>(
  (ref) => NotificationHandler(ref),
);

/// Turns an arriving push into something the app does.
///
/// Three cases, and all three have to be handled or a notification is
/// silently lost: one that arrives while the app is open, one tapped
/// while the app is in the background, and one tapped while the app was
/// not running at all.
class NotificationHandler {
  NotificationHandler(this._ref);

  final Ref _ref;
  final List<StreamSubscription<void>> _subscriptions = [];
  bool _started = false;

  Future<void> start({
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    if (_started) return;
    _started = true;

    // Tapped while the app was terminated. This one is a single future,
    // not a stream, and is the case most often forgotten.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _openFor(router, initial);

    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openFor(router, message),
      ),
    );

    // In the foreground the system tray shows nothing, so without this
    // an announcement that lands while the member is using the app would
    // never be seen.
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(
        (message) => _showInApp(router, messengerKey, message),
      ),
    );

    // A rotated token has to be written back, or the member quietly
    // stops receiving anything.
    final messaging = _ref.read(messagingServiceProvider);
    _subscriptions.add(
      messaging.onTokenRefresh.listen((_) => _reregister()),
    );
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _reregister() async {
    // Read straight from Firebase Auth rather than the session, which
    // would make this depend on the controller that already depends on
    // the messaging service.
    final uid = _ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid != null) {
      await _ref.read(messagingServiceProvider).registerToken(uid);
    }
  }

  void _showInApp(
    GoRouter router,
    GlobalKey<ScaffoldMessengerState> messengerKey,
    RemoteMessage message,
  ) {
    final title = message.notification?.title ?? message.data['title'];
    if (title == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(title),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _openFor(router, message),
        ),
      ),
    );
  }

  /// Sends the member where the notification points.
  ///
  /// The route is read from the payload rather than inferred, so a new
  /// kind of notification needs no app release; an unrecognised one falls
  /// back to the notices list instead of doing nothing.
  void _openFor(GoRouter router, RemoteMessage message) {
    router.go(routeFor(message.data));
  }

  /// Visible for testing: the payload-to-route mapping.
  static String routeFor(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String && route.startsWith('/')) return route;

    return switch (data['type']) {
      'class_reminder' || 'booking_promoted' => '/classes',
      'event_reminder' => '/events',
      'plan_assigned' || 'inactivity' => '/plan',
      'membership_expiry' => '/profile',
      _ => '/notices',
    };
  }
}
