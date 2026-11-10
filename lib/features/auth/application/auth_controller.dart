import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/services/auth_service.dart';
import 'package:deepfitness/core/services/messaging_service.dart';
import 'package:deepfitness/features/auth/data/member_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the signed-in user stands, which is what the router redirects on.
enum AuthStage {
  /// No Firebase user.
  signedOut,

  /// Signed in, but no member document yet: first login goes to onboarding.
  needsProfile,

  /// Signed in with a profile.
  ready,
}

class AuthSession {
  const AuthSession({
    required this.stage,
    this.user,
    this.member,
    this.role = UserRole.member,
  });

  const AuthSession.signedOut()
    : stage = AuthStage.signedOut,
      user = null,
      member = null,
      role = UserRole.member;

  final AuthStage stage;
  final User? user;
  final Member? member;
  final UserRole role;

  bool get isSignedIn => stage != AuthStage.signedOut;

  /// A lapsed membership keeps the member signed in; the app shows the
  /// renewal screen and their own history stays readable.
  bool get isLapsed => member?.isLapsed ?? false;
}

final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

/// Holds the session: the Firebase user, their role claim and their member
/// document, rebuilt whenever Firebase reports a sign-in or sign-out.
class AuthController extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    final user = await ref.watch(authStateChangesProvider.future);
    if (user == null) return const AuthSession.signedOut();

    final role = await ref.read(authServiceProvider).currentRole();
    final member = await ref.read(memberRepositoryProvider).find(user.uid);

    if (member == null) {
      return AuthSession(
        stage: AuthStage.needsProfile,
        user: user,
        role: role ?? UserRole.member,
      );
    }

    // The device may have signed in before permission was ever asked for,
    // so the token is refreshed on every resolved session, not just on the
    // sign-in that created the profile.
    await _registerForPush(user.uid);

    return AuthSession(
      stage: AuthStage.ready,
      user: user,
      member: member,
      role: role ?? UserRole.member,
    );
  }

  /// Creates the member document after a first sign-in, then re-resolves.
  Future<void> completeProfile({required String name}) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(memberRepositoryProvider)
          .createProfile(
            uid: user.uid,
            name: name,
            phone: user.phoneNumber,
            email: user.email,
          );
      // The auth trigger may have written the document a moment earlier;
      // either way the read below is the one that decides the stage.
      final member = await ref.read(memberRepositoryProvider).find(user.uid);
      await _registerForPush(user.uid);
      return AuthSession(
        stage: member == null ? AuthStage.needsProfile : AuthStage.ready,
        user: user,
        member: member,
        role: await ref.read(authServiceProvider).currentRole() ??
            UserRole.member,
      );
    });
  }

  /// Signs out, dropping this device's push token first.
  ///
  /// The order matters: once signed out the rules no longer allow writing
  /// the member document, so the token would be stranded and the member
  /// would keep receiving pushes on a device they had left.
  Future<void> signOut() async {
    final user = ref.read(authServiceProvider).currentUser;
    state = const AsyncLoading();

    if (user != null) {
      try {
        await ref.read(messagingServiceProvider).unregisterToken(user.uid);
      } catch (_) {
        // A token that cannot be removed must not block the sign-out; the
        // next send prunes it when delivery fails.
      }
    }

    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(AuthSession.signedOut());
  }

  Future<void> _registerForPush(String uid) async {
    try {
      final messaging = ref.read(messagingServiceProvider);
      if (await messaging.requestPermission()) {
        await messaging.registerToken(uid);
      }
    } catch (_) {
      // Push is not required to use the app; a failure here is not worth
      // blocking the session on.
    }
  }
}
