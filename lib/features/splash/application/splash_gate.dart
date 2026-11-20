import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the splash is held before the app moves on.
///
/// Long enough to actually register as a brand moment rather than a flicker.
/// It is a floor, not a delay added on top: the wait runs while Firebase
/// restores the session, so on a cold start most of it is work that had to
/// happen anyway.
const splashHold = Duration(milliseconds: 2400);

/// Whether the splash has had its moment.
///
/// The router parks on `/splash` until this flips. It exists because
/// "authentication resolved" and "the member saw the splash" are different
/// events, and the router was treating them as one: on a warm start Firebase
/// answers in a few milliseconds, so the redirect fired almost immediately
/// and neither splash was ever really seen.
///
/// Set once per app launch. A later sign-out does not re-arm it, because the
/// splash is for opening the app, not for every trip back to the sign-in
/// screen.
final splashGateProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);

class SplashGate extends Notifier<bool> {
  @override
  bool build() => false;

  /// Called by the splash once its minimum hold has elapsed *and* the session
  /// has resolved, so the router never lands somewhere it would immediately
  /// have to correct.
  void release() {
    if (!state) state = true;
  }
}
