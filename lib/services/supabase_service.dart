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

  final SupabaseClient? _client;

  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient get client {
    final injected = _client;
    if (injected != null) return injected;
    return Supabase.instance.client;
  }
}
