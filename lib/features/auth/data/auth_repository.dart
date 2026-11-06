import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/config/firebase_config.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/app_firebase.dart';
import 'package:deepfitness/core/utils/firestore_values.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(appFirebaseProvider));
});

/// Handed back when an OTP has been sent, so the screen can confirm the code
/// without knowing anything about the Firebase SDK.
class PhoneVerification {
  const PhoneVerification({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
}

/// What the app knows about the signed-in account before any profile is read.
class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    required this.role,
    required this.hasProfile,
    this.email,
    this.phone,
  });

  final String uid;

  /// Null when the custom claim has not been set yet — a brand-new account
  /// that `onMemberCreate` has not finished provisioning.
  final UserRole? role;

  /// False when the account exists in Auth but has no member document, which
  /// is what sends the router to onboarding.
  final bool hasProfile;
  final String? email;
  final String? phone;
}

class AuthRepository {
  const AuthRepository(this._firebase);

  final AppFirebase _firebase;

  bool get isConfigured => _firebase.isConfigured;

  User? get currentUser => isConfigured ? _firebase.auth.currentUser : null;

  /// Fires on sign-in, sign-out and token refresh — the token matters because
  /// a role claim change only reaches the client on a refresh.
  Stream<User?> get authStateChanges {
    if (!isConfigured) return const Stream.empty();
    return _firebase.auth.idTokenChanges();
  }

  // ---------------------------------------------------------------- phone OTP

  /// Sends an OTP. The primary sign-in method, per the guide.
  ///
  /// On Android the SMS can be auto-retrieved, in which case [onAutoVerified]
  /// fires and no code needs typing.
  Future<PhoneVerification> sendOtp({
    required String phoneNumber,
    void Function(UserCredential credential)? onAutoVerified,
    int? resendToken,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final normalized = normalizePhone(phoneNumber);
      final completer = Completer<PhoneVerification>();

      await _firebase.auth.verifyPhoneNumber(
        phoneNumber: normalized,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (onAutoVerified == null) return;
          try {
            final result = await _firebase.auth.signInWithCredential(
              credential,
            );
            onAutoVerified(result);
          } catch (_) {
            // Auto-retrieval is a convenience; the typed code still works.
          }
        },
        verificationFailed: (error) {
          if (completer.isCompleted) return;
          completer.completeError(error, StackTrace.current);
        },
        codeSent: (verificationId, token) {
          if (completer.isCompleted) return;
          completer.complete(
            PhoneVerification(
              verificationId: verificationId,
              phoneNumber: normalized,
              resendToken: token,
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (completer.isCompleted) return;
          completer.complete(
            PhoneVerification(
              verificationId: verificationId,
              phoneNumber: normalized,
            ),
          );
        },
      );

      return completer.future;
    }, whileDoing: 'sending your code');
  }

  Future<UserCredential> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return _firebase.auth.signInWithCredential(credential);
    }, whileDoing: 'checking your code');
  }

  // -------------------------------------------------------------------- email

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      return _firebase.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }, whileDoing: 'signing you in');
  }

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return guard(() async {
      _firebase.requireConfigured();
      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return credential;
    }, whileDoing: 'creating your account');
  }

  Future<void> resetPassword(String email) {
    return guard(() async {
      _firebase.requireConfigured();
      await _firebase.auth.sendPasswordResetEmail(email: email.trim());
    }, whileDoing: 'sending your reset email');
  }

  // --------------------------------------------------------------- identity

  /// Reads the role from the custom claim, falling back to the member document
  /// only while the claim is still being provisioned.
  ///
  /// The claim is the authority — the document field is never trusted for
  /// access decisions, it just avoids a blank first screen.
  Future<AuthIdentity?> fetchIdentity({bool refreshToken = false}) {
    return guard(() async {
      if (!isConfigured) return null;
      final user = _firebase.auth.currentUser;
      if (user == null) return null;

      final token = await user.getIdTokenResult(refreshToken);
      final claim = token.claims?['role']?.toString();

      final doc = await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(user.uid)
          .get();

      final role = _roleFrom(claim) ?? _roleFrom(doc.data()?['role']);

      return AuthIdentity(
        uid: user.uid,
        role: role,
        hasProfile: doc.exists && doc.data()?[BaseFields.deletedAt] == null,
        email: user.email,
        phone: user.phoneNumber,
      );
    }, whileDoing: 'checking your account');
  }

  /// Waits for `onMemberCreate` to set the role claim on a new account.
  ///
  /// The function runs on an Auth trigger, so the client can reach this point
  /// a beat before the claim exists. Without the wait a new member would land
  /// on onboarding and be bounced straight back out.
  Future<AuthIdentity?> awaitProvisionedIdentity({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var delay = const Duration(milliseconds: 400);

    while (DateTime.now().isBefore(deadline)) {
      final identity = await fetchIdentity(refreshToken: true);
      if (identity == null) return null;
      if (identity.role != null && identity.hasProfile) return identity;
      await Future<void>.delayed(delay);
      delay *= 2;
    }

    return fetchIdentity(refreshToken: true);
  }

  Future<Member?> fetchMember() {
    return guard(() async {
      if (!isConfigured) return null;
      final uid = _firebase.auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return Member.fromFirestore(doc);
    }, whileDoing: 'loading your profile');
  }

  /// Creates the member document for an account that signed itself up.
  ///
  /// `onMemberCreate` does this server-side for every new account; this is the
  /// idempotent client-side completion of the fields only the app knows, such
  /// as the name typed on the sign-up form.
  Future<void> completeProfile({
    required String name,
    String? goal,
    String? gender,
    int? age,
    double? heightCm,
  }) {
    return guard(() async {
      final uid = _firebase.requireUserId();
      final user = _firebase.auth.currentUser!;
      await _firebase.firestore
          .collection(FirestorePaths.members)
          .doc(uid)
          .set({
            'name': name.trim(),
            'email': user.email ?? '',
            'phone': user.phoneNumber,
            'role': 'member',
            'membershipStatus': MembershipStatus.active.name,
            'joinedAt': FieldValue.serverTimestamp(),
            'goal': ?goal,
            'gender': ?gender,
            'age': ?age,
            'heightCm': ?heightCm,
            ...BaseFields.onCreate(by: uid),
          }, SetOptions(merge: true));
    }, whileDoing: 'saving your profile');
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _firebase.auth.signOut();
  }

  // ------------------------------------------------------------------ helpers

  static UserRole? _roleFrom(Object? value) {
    switch (value?.toString()) {
      case 'admin':
        return UserRole.admin;
      case 'trainer':
        return UserRole.trainer;
      case 'member':
        return UserRole.member;
      default:
        return null;
    }
  }

  static bool looksLikeEmail(String value) => value.contains('@');

  /// Phone numbers are stored and sent in E.164. A number typed without a
  /// country code gets the gym's own.
  static String normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[\s()-]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) {
      return '${FirebaseConfig.defaultPhoneCountryCode}${digits.substring(1)}';
    }
    return '${FirebaseConfig.defaultPhoneCountryCode}$digits';
  }
}
