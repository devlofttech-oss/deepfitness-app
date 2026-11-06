import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Why a repository call failed, in terms a screen can act on.
enum FailureKind {
  /// Signed out, or the session expired.
  unauthenticated,

  /// Signed in, but the rules refused the read or write.
  permissionDenied,

  /// The document or collection has nothing to return.
  notFound,

  /// Offline, timed out, or the backend was unreachable.
  network,

  /// A write lost a race, or a transaction ran out of retries.
  conflict,

  /// The caller passed something the backend rejected.
  invalid,

  /// Firebase was never initialised for this build.
  notConfigured,

  unknown,
}

/// The only error type repositories throw.
///
/// Screens show [message]; they never see a raw `FirebaseException`.
class RepositoryFailure implements Exception {
  const RepositoryFailure(
    this.kind,
    this.message, {
    this.code,
    this.cause,
    this.stackTrace,
  });

  final FailureKind kind;
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isAuthProblem =>
      kind == FailureKind.unauthenticated || kind == FailureKind.permissionDenied;

  @override
  String toString() => message;
}

/// Runs [action] and maps anything it throws to a [RepositoryFailure].
///
/// Every public repository method body goes through this, so no screen can
/// ever receive a backend exception by accident.
Future<T> guard<T>(
  Future<T> Function() action, {
  String? whileDoing,
  Duration timeout = const Duration(seconds: 20),
}) async {
  try {
    return await action().timeout(timeout);
  } on RepositoryFailure {
    rethrow;
  } on TimeoutException catch (error, stackTrace) {
    throw RepositoryFailure(
      FailureKind.network,
      whileDoing == null
          ? 'That took too long. Check your connection and try again.'
          : 'Timed out while $whileDoing. Check your connection and try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  } on FirebaseAuthException catch (error, stackTrace) {
    throw RepositoryFailure(
      _authKind(error.code),
      _authMessage(error),
      code: error.code,
      cause: error,
      stackTrace: stackTrace,
    );
  } on FirebaseException catch (error, stackTrace) {
    throw RepositoryFailure(
      _firestoreKind(error.code),
      _firestoreMessage(error, whileDoing),
      code: error.code,
      cause: error,
      stackTrace: stackTrace,
    );
  } on StateError catch (error, stackTrace) {
    throw RepositoryFailure(
      error.message.contains('not logged in')
          ? FailureKind.unauthenticated
          : FailureKind.invalid,
      error.message,
      cause: error,
      stackTrace: stackTrace,
    );
  } catch (error, stackTrace) {
    throw RepositoryFailure(
      FailureKind.unknown,
      whileDoing == null
          ? 'Something went wrong. Please try again.'
          : 'Something went wrong while $whileDoing.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

FailureKind _firestoreKind(String code) {
  switch (code) {
    case 'permission-denied':
      return FailureKind.permissionDenied;
    case 'unauthenticated':
      return FailureKind.unauthenticated;
    case 'not-found':
      return FailureKind.notFound;
    case 'unavailable':
    case 'deadline-exceeded':
      return FailureKind.network;
    case 'aborted':
    case 'already-exists':
    case 'failed-precondition':
      return FailureKind.conflict;
    case 'invalid-argument':
    case 'out-of-range':
      return FailureKind.invalid;
    default:
      return FailureKind.unknown;
  }
}

String _firestoreMessage(FirebaseException error, String? whileDoing) {
  switch (error.code) {
    case 'permission-denied':
      return 'You do not have access to that.';
    case 'unauthenticated':
      return 'Please sign in again.';
    case 'not-found':
      return 'That is no longer available.';
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Cannot reach Deep Fitness right now. Check your connection.';
    case 'aborted':
      return 'Someone else changed that at the same time. Please try again.';
    case 'failed-precondition':
      return 'That cannot be done right now. Please try again.';
    default:
      return whileDoing == null
          ? 'Something went wrong. Please try again.'
          : 'Something went wrong while $whileDoing.';
  }
}

FailureKind _authKind(String code) {
  switch (code) {
    case 'network-request-failed':
      return FailureKind.network;
    case 'user-not-found':
      return FailureKind.notFound;
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-verification-code':
    case 'invalid-phone-number':
    case 'invalid-email':
    case 'weak-password':
      return FailureKind.invalid;
    case 'email-already-in-use':
    case 'credential-already-in-use':
      return FailureKind.conflict;
    case 'user-disabled':
    case 'operation-not-allowed':
      return FailureKind.permissionDenied;
    case 'too-many-requests':
      return FailureKind.conflict;
    default:
      return FailureKind.unknown;
  }
}

String _authMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-phone-number':
      return 'That phone number does not look right.';
    case 'invalid-verification-code':
      return 'That code is not correct. Check it and try again.';
    case 'session-expired':
      return 'That code has expired. Ask for a new one.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Those details do not match an account.';
    case 'email-already-in-use':
      return 'An account already uses that email.';
    case 'weak-password':
      return 'Choose a longer password.';
    case 'user-disabled':
      return 'That account has been disabled. Please contact the gym.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Cannot reach Deep Fitness right now. Check your connection.';
    case 'operation-not-allowed':
      return 'That sign-in method is not enabled for this app.';
    default:
      return 'Could not sign you in. Please try again.';
  }
}
