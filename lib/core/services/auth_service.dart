import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);

/// A phone sign-in waiting for the member to type the code.
class PendingVerification {
  const PendingVerification({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
}

/// Firebase Authentication, wrapped so the rest of the app never imports the
/// SDK directly and every error arrives as a [RepositoryFailure].
class AuthService {
  const AuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The role from the token's custom claim.
  ///
  /// [refresh] forces a token refresh, which is needed right after a role is
  /// changed by the `setUserRole` function: the cached token still carries
  /// the old claim until it is re-fetched.
  Future<UserRole?> currentRole({bool refresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final token = await user.getIdTokenResult(refresh);
      final claim = token.claims?['role'];
      if (claim == null) return null;
      return UserRole.fromClaim(claim);
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  /// Starts phone sign-in, the primary method.
  ///
  /// On Android the SMS can be auto-retrieved, in which case [onAutoVerified]
  /// fires and no code is ever typed; [onCodeSent] is the path everywhere
  /// else. Exactly one of the three callbacks runs per attempt.
  Future<void> startPhoneSignIn({
    required String phoneNumber,
    required void Function(PendingVerification) onCodeSent,
    required void Function(RepositoryFailure) onFailed,
    required void Function(UserCredential) onAutoVerified,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: normalizePhone(phoneNumber),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          onAutoVerified(await _auth.signInWithCredential(credential));
        } on FirebaseAuthException catch (error) {
          onFailed(RepositoryFailure.fromAuth(error));
        }
      },
      verificationFailed: (error) =>
          onFailed(RepositoryFailure.fromAuth(error)),
      codeSent: (verificationId, token) => onCodeSent(
        PendingVerification(
          verificationId: verificationId,
          phoneNumber: normalizePhone(phoneNumber),
          resendToken: token,
        ),
      ),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Completes phone sign-in with the code the member typed.
  Future<UserCredential> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      return await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode.trim(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  /// Email and password, the fallback method.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw RepositoryFailure.fromAuth(error);
    }
  }

  Future<void> signOut() => _auth.signOut();
}

/// Puts a typed number into the E.164 form Firebase requires.
///
/// A number with no country code is treated as Indian, which is where the
/// gym is; anything already carrying a `+` is left as the member typed it.
String normalizePhone(String value, {String defaultCountryCode = '+91'}) {
  final digits = value.replaceAll(RegExp(r'[\s()-]'), '');
  if (digits.startsWith('+')) return digits;
  final national = digits.startsWith('0') ? digits.substring(1) : digits;
  return '$defaultCountryCode$national';
}
