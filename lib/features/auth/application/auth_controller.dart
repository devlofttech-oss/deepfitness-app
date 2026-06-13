import 'package:deepfitness/features/auth/data/auth_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSessionState>(AuthController.new);

class AuthSessionState {
  const AuthSessionState({
    required this.isAuthenticated,
    required this.isSupabaseConfigured,
    this.email,
    this.role,
  });

  final bool isAuthenticated;
  final bool isSupabaseConfigured;
  final String? email;
  final UserRole? role;

  AuthSessionState copyWith({
    bool? isAuthenticated,
    bool? isSupabaseConfigured,
    String? email,
    UserRole? role,
  }) {
    return AuthSessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSupabaseConfigured: isSupabaseConfigured ?? this.isSupabaseConfigured,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class AuthController extends AsyncNotifier<AuthSessionState> {
  @override
  Future<AuthSessionState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final user = repository.currentUser;
    final role = await repository.fetchCurrentRole();

    return AuthSessionState(
      isAuthenticated: user != null,
      isSupabaseConfigured: repository.isConfigured,
      email: user?.email,
      role: role,
    );
  }

  Future<bool> signIn({
    required String identifier,
    required String password,
    required UserRole expectedRole,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signInWithPassword(
        identifier: identifier,
        password: password,
      );

      final userEmail = response?.user?.email ?? identifier;
      final role = await repository.fetchCurrentRole();
      if (role != expectedRole) {
        await repository.signOut();
        final portal = expectedRole == UserRole.trainer ? 'trainer' : 'member';
        throw StateError('Use the $portal login for this account.');
      }
      state = AsyncData(
        AuthSessionState(
          isAuthenticated: true,
          isSupabaseConfigured: repository.isConfigured,
          email: userEmail,
          role: role,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> createMemberAccount({
    required String name,
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUpMember(
        name: name,
        identifier: identifier,
        password: password,
      );
      final role = await repository.fetchCurrentRole() ?? UserRole.member;
      state = AsyncData(
        AuthSessionState(
          isAuthenticated: response.user != null,
          isSupabaseConfigured: repository.isConfigured,
          email: response.user?.email ?? identifier,
          role: role,
        ),
      );
      return response.user != null;
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
    await repository.signOut();
    state = AsyncData(
      AuthSessionState(
        isAuthenticated: false,
        isSupabaseConfigured: repository.isConfigured,
      ),
    );
  }
}
