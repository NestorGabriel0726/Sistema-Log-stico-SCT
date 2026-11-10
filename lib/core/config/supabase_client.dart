import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a globally accessible Supabase client instance.
/// The client is initialized in `main.dart` when the environment variables
/// `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided. If they are not set,
/// `Supabase.instance.client` will still be available but will throw if used.
/// Consumers should guard calls with `backendModeProvider` or by checking
/// `Supabase.instance.client.session`.
final supabaseClient = Supabase.instance.client;

