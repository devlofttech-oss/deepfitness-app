import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/services/push_service.dart';
import 'package:deepfitness/features/auth/data/auth_repository.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSessionState>(AuthController.new);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Holds the OTP in flight between the "send code" and "confirm code" steps.
final phoneVerificationProvider =
    NotifierProvider<PhoneVerificationController, PhoneVerification?>(
      PhoneVerificationController.new,
    );

class PhoneVerificationController extends Notifier<PhoneVerification?> {
  @override
  PhoneVerification? build() => null;

  void set(PhoneVerification verification) => state = verification;

  void clear() => state = null;
}

class AuthSessionState {
  const AuthSessionState({
    required this.isAuthenticated,
    required this.isBackendConfigured,
    this.userId,
    this.email,
    this.phone,
    this.role,
    this.hasProfile = false,
    this.membershipStatus = MembershipStatus.active,
    this.membershipExpiresAt,
  });

  final bool isAuthenticated;

  /// False when this build has no Firebase project, so screens can say so
  /// rather than showing an endless spinner.
  final bool isBackendConfigured;
  final String? userId;
  final String? email;
  final String? phone;
  final UserRole? role;

  /// Signed in but with no member document yet — the router sends these
  /// accounts to onboarding.
  final bool hasProfile;
  final MembershipStatus membershipStatus;
  final DateTime? membershipExpiresAt;

  /// A lapsed membership is a state, not a sign-out: the member keeps read
  /// access to their own history and sees a renewal screen.
  bool get isLapsed {
    if (role != UserRole.member) return false;
    if (membershipStatus != MembershipStatus.active) return true;
    final expiry = membershipExpiresAt;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool get needsOnboarding => isAuthenticated && !hasProfile;

  AuthSessionState copyWith({
    bool? isAuthenticated,
    bool? isBackendConfigured,
    String? userId,
    String? email,
    String? phone,
    UserRole? role,
    bool? hasProfile,
    MembershipStatus? membershipStatus,
    DateTime? membershipExpiresAt,
  }) {
    return AuthSessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBackendConfigured: isBackendConfigured ?? this.isBackendConfigured,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hasProfile: hasProfile ?? this.hasProfile,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
    );
  }
}

class AuthController extends AsyncNotifier<AuthSessionState> {
  @override
  Future<AuthSessionState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    // Rebuilds the session whenever the token changes, which is how a role
    // claim set after sign-up reaches the app.
    ref.watch(authStateChangesProvider);

    if (!repository.isConfigured || repository.currentUser == null) {
      return AuthSessionState(
        isAuthenticated: false,
        isBackendConfigured: repository.isConfigured,
      );
    }

    return _sessionFromIdentity(repository);
  }

  Future<AuthSessionState> _sessionFromIdentity(
    AuthRepository repository, {
    bool refreshToken = false,
  }) async {
    final identity = await repository.fetchIdentity(refreshToken: refreshToken);
    if (identity == null) {
      return AuthSessionState(
        isAuthenticated: false,
        isBackendConfigured: repository.isConfigured,
      );
    }

    final member = identity.hasProfile ? await repository.fetchMember() : null;

    return AuthSessionState(
      isAuthenticated: true,
      isBackendConfigured: repository.isConfigured,
      userId: identity.uid,
      email: identity.email,
      phone: identity.phone,
      role: identity.role,
      hasProfile: identity.hasProfile,
      membershipStatus: member?.membershipStatus ?? MembershipStatus.active,
      membershipExpiresAt: member?.expiryDate,
    );
  }

  /// Sends the OTP and parks the verification id for the confirm step.
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final verification = await repository.sendOtp(phoneNumber: phoneNumber);
      ref.read(phoneVerificationProvider.notifier).set(verification);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> confirmOtp({
    required String smsCode,
    required UserRole expectedRole,
  }) async {
    final verification = ref.read(phoneVerificationProvider);
    if (verification == null) {
      state = AsyncError(
        const RepositoryFailure(
          FailureKind.invalid,
          'Ask for a code before confirming one.',
        ),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.confirmOtp(
        verificationId: verification.verificationId,
        smsCode: smsCode,
      );
      return _finishSignIn(repository, expectedRole: expectedRole);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithEmail(email: email, password: password);
      return _finishSignIn(repository, expectedRole: expectedRole);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Signs in whichever way the typed identifier suggests.
  ///
  /// Phone is the primary method, so anything that is not an email address is
  /// treated as a number and routed through the OTP flow.
  Future<bool> signIn({
    required String identifier,
    required String password,
    required UserRole expectedRole,
  }) {
    if (AuthRepository.looksLikeEmail(identifier)) {
      return signInWithEmail(
        email: identifier,
        password: password,
        expectedRole: expectedRole,
      );
    }
    return sendOtp(identifier);
  }

  Future<bool> createMemberAccount({
    required String name,
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);

      if (!AuthRepository.looksLikeEmail(identifier)) {
        // Phone sign-up is the same OTP flow; the profile is completed once
        // the code is confirmed.
        state = await AsyncValue.guard(() => build());
        return sendOtp(identifier);
      }

      await repository.signUpWithEmail(
        name: name,
        email: identifier,
        password: password,
      );
      await repository.awaitProvisionedIdentity();
      await repository.completeProfile(name: name);
      await ref.read(pushServiceProvider).start();

      state = AsyncData(await _sessionFromIdentity(repository, refreshToken: true));
      return state.value?.isAuthenticated ?? false;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Shared tail of every sign-in: wait for provisioning, check the portal
  /// matches the role, register for push.
  Future<bool> _finishSignIn(
    AuthRepository repository, {
    required UserRole expectedRole,
  }) async {
    final identity = await repository.awaitProvisionedIdentity();

    if (identity == null) {
      state = AsyncData(
        AuthSessionState(
          isAuthenticated: false,
          isBackendConfigured: repository.isConfigured,
        ),
      );
      return false;
    }

    // A trainer signing in on the member screen (or the reverse) is sent back
    // rather than quietly dropped into the wrong app. An admin is staff, so
    // the trainer portal accepts them.
    final matches = expectedRole == UserRole.trainer
        ? (identity.role?.isStaff ?? false)
        : identity.role == expectedRole;
    if (identity.role != null && !matches) {
      await repository.signOut();
      final portal = expectedRole == UserRole.trainer ? 'trainer' : 'member';
      state = AsyncError(
        RepositoryFailure(
          FailureKind.permissionDenied,
          'Use the $portal login for this account.',
        ),
        StackTrace.current,
      );
      return false;
    }

    await ref.read(pushServiceProvider).start();
    ref.read(phoneVerificationProvider.notifier).clear();

    final session = await _sessionFromIdentity(repository, refreshToken: true);
    state = AsyncData(session);
    return session.isAuthenticated;
  }

  /// Fills in the member document for an account that has none yet.
  Future<bool> completeOnboarding({
    required String name,
    String? goal,
    String? gender,
    int? age,
    double? heightCm,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.completeProfile(
        name: name,
        goal: goal,
        gender: gender,
        age: age,
        heightCm: heightCm,
      );
      state = AsyncData(await _sessionFromIdentity(repository));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    await ref.read(authRepositoryProvider).resetPassword(email);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);
    await ref.read(pushServiceProvider).stop();
    await repository.signOut();
    ref.read(phoneVerificationProvider.notifier).clear();
    state = AsyncData(
      AuthSessionState(
        isAuthenticated: false,
        isBackendConfigured: repository.isConfigured,
      ),
    );
  }
}
