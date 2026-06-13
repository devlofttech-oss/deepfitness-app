class SupabaseConfig {
  const SupabaseConfig._();

  static const _fallbackUrl = 'https://iqhrhxxvhtokqltqkqoz.supabase.co';
  static const _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxaHJoeHh2aHRva3FsdHFrcW96Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1MDEwNjUsImV4cCI6MjA5NjA3NzA2NX0.QtW5sBct0iKksJXu8BqeJpqlBE_xsvh9zyEaqxInswU';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _fallbackUrl,
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _fallbackAnonKey,
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
