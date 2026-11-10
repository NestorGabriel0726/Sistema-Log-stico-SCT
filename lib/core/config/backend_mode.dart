import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

enum BackendMode { local, supabase }

/// Active backend. Always `local` unless Supabase was initialized with
/// non-empty credentials and `SCT_BACKEND=supabase`.
final backendModeProvider = Provider<BackendMode>((ref) {
  return AppConfig.canUseSupabase ? BackendMode.supabase : BackendMode.local;
});
