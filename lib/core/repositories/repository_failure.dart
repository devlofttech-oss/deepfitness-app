import 'package:firebase_auth/firebase_auth.dart';

/// Why a repository call did not succeed.
///
/// Repositories catch the Firebase exceptions and return one of these, so a
/// screen shows a sentence a member can act on rather than a raw error.
enum FailureKind {
  permissionDenied,
  notFound,
  network,
  conflict,
  invalidInput,
  rateLimited,
  unknown,
}

class RepositoryFailure implements Exception {
  const RepositoryFailure(this.kind, this.message, {this.cause});

  /// Maps a Firestore error onto a failure a screen can show.
  factory RepositoryFailure.fromFirestore(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => RepositoryFailure(
        FailureKind.permissionDenied,
        'You do not have access to this.',
        cause: error,
      ),
      'not-found' => RepositoryFailure(
        FailureKind.notFound,
        'That is no longer available.',
        cause: error,
      ),
      'unavailable' || 'deadline-exceeded' => RepositoryFailure(
        FailureKind.network,
        'No connection. Check your network and try again.',
        cause: error,
      ),
      'aborted' || 'failed-precondition' => RepositoryFailure(
        FailureKind.conflict,
        'Someone else changed this first. Try again.',
        cause: error,
      ),
      'invalid-argument' => RepositoryFailure(
        FailureKind.invalidInput,
        'Some of those details are not valid.',
        cause: error,
      ),
      'resource-exhausted' => RepositoryFailure(
        FailureKind.rateLimited,
        'Too many attempts. Wait a moment and try again.',
        cause: error,
      ),
      _ => RepositoryFailure(
        FailureKind.unknown,
        'Something went wrong. Try again.',
        cause: error,
      ),
    };
  }

  /// Maps a sign-in error onto a failure, keeping the wording specific
  /// enough to be useful without saying which half of a login was wrong.
  factory RepositoryFailure.fromAuth(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-verification-code' => RepositoryFailure(
        FailureKind.invalidInput,
        'That code is not right. Check it and try again.',
        cause: error,
      ),
      'session-expired' || 'code-expired' => RepositoryFailure(
        FailureKind.invalidInput,
        'That code has expired. Request a new one.',
        cause: error,
      ),
      'invalid-phone-number' => RepositoryFailure(
        FailureKind.invalidInput,
        'That phone number is not valid.',
        cause: error,
      ),
      'invalid-email' => RepositoryFailure(
        FailureKind.invalidInput,
        'That email address is not valid.',
        cause: error,
      ),
      'user-disabled' => RepositoryFailure(
        FailureKind.permissionDenied,
        'This account has been disabled. Contact the gym.',
        cause: error,
      ),
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => RepositoryFailure(
        FailureKind.invalidInput,
        'Those sign-in details are not right.',
        cause: error,
      ),
      'email-already-in-use' => RepositoryFailure(
        FailureKind.conflict,
        'An account already exists for that email.',
        cause: error,
      ),
      'weak-password' => RepositoryFailure(
        FailureKind.invalidInput,
        'Choose a longer password.',
        cause: error,
      ),
      'too-many-requests' => RepositoryFailure(
        FailureKind.rateLimited,
        'Too many attempts. Wait a few minutes and try again.',
        cause: error,
      ),
      'network-request-failed' => RepositoryFailure(
        FailureKind.network,
        'No connection. Check your network and try again.',
        cause: error,
      ),
      _ => RepositoryFailure(
        FailureKind.unknown,
        'Could not sign you in. Try again.',
        cause: error,
      ),
    };
  }

  final FailureKind kind;

  /// Shown to the member as-is, so it stays a plain sentence.
  final String message;

  final Object? cause;

  @override
  String toString() => 'RepositoryFailure(${kind.name}): $message';
}
