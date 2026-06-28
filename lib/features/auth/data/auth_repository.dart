import 'package:deepfitness/services/supabase_service.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseServiceProvider));
});

class AuthRepository {
  const AuthRepository(this._supabaseService);

  final SupabaseService _supabaseService;

  bool get isConfigured => _supabaseService.isConfigured;

  User? get currentUser {
    if (!isConfigured) return null;
    return _supabaseService.client.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges {
    if (!isConfigured) return const Stream.empty();
    return _supabaseService.client.auth.onAuthStateChange;
  }

  Future<AuthResponse?> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    if (!isConfigured) throw StateError('Supabase is not configured.');
    final normalized = identifier.trim();
    return _supabaseService.client.auth.signInWithPassword(
      email: _isEmail(normalized) ? normalized : null,
      phone: _isEmail(normalized) ? null : _normalizePhone(normalized),
      password: password,
    );
  }

  Future<AuthResponse> signUpMember({
    required String name,
    required String identifier,
    required String password,
  }) async {
    if (!isConfigured) throw StateError('Supabase is not configured.');
    final normalized = identifier.trim();
    return _supabaseService.client.auth.signUp(
      email: _isEmail(normalized) ? normalized : null,
      phone: _isEmail(normalized) ? null : _normalizePhone(normalized),
      password: password,
      data: {'name': name.trim(), 'role': 'member'},
    );
  }

  Future<void> resetPassword(String email) async {
    if (!isConfigured) throw StateError('Supabase is not configured.');
    await _supabaseService.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _supabaseService.client.auth.signOut();
  }

  Future<UserRole?> fetchCurrentRole() async {
    if (!isConfigured || currentUser == null) return null;
    final row = await _supabaseService.client
        .from('users')
        .select('role')
        .eq('id', currentUser!.id)
        .maybeSingle();
    final role = row?['role'] ?? currentUser?.userMetadata?['role'];
    if (role == null) return null;
    return role == 'trainer' ? UserRole.trainer : UserRole.member;
  }

  bool _isEmail(String value) => value.contains('@');

  String _normalizePhone(String value) {
    final phone = value.replaceAll(RegExp(r'\s+'), '');
    return phone.startsWith('+') ? phone : '+91$phone';
  }
}
