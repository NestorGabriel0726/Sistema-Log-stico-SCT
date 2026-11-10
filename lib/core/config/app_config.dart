/// Compile-time and runtime backend configuration.
///
/// Default is local demo mode. Supabase is used only when both credentials
/// are provided *and* `SCT_BACKEND=supabase`.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const requestedBackend =
      String.fromEnvironment('SCT_BACKEND', defaultValue: 'local');

  /// Set in `main()` after a successful `Supabase.initialize()`.
  static bool supabaseInitialized = false;

  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get wantsSupabase =>
      requestedBackend.toLowerCase() == 'supabase';

  static bool get canUseSupabase =>
      wantsSupabase && supabaseConfigured && supabaseInitialized;
}
