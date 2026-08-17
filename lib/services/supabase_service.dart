import 'package:deepfitness/core/config/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);

class SupabaseService {
  // Keeps the public constructor name clear while allowing test injection.
  // ignore: prefer_initializing_formals
  SupabaseService({SupabaseClient? client}) : _client = client;

  static bool _isInitialized = false;

  static void markInitialized() {
    _isInitialized = true;
  }

  static void markUnavailable() {
    _isInitialized = false;
  }

  final SupabaseClient? _client;

  bool get isConfigured =>
      _client != null || (SupabaseConfig.isConfigured && _isInitialized);

  SupabaseClient get client {
    final injected = _client;
    if (injected != null) return injected;
    return Supabase.instance.client;
  }
}
