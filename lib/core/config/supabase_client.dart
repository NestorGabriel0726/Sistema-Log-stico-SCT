import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// Returns the SDK client only after a successful initialize. Never call
/// `Supabase.instance.client` at import time — that throws when the app
/// runs in local demo mode without credentials.
SupabaseClient? tryGetSupabaseClient() {
  if (!AppConfig.supabaseInitialized) return null;
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return tryGetSupabaseClient();
});
