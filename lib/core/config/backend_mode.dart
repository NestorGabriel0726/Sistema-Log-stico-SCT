// Backend mode enumeration and provider

enum BackendMode { local, supabase }

// Riverpod provider to select active backend (default: local).
// The app can override this provider at runtime to switch implementations.

import 'package:flutter_riverpod/flutter_riverpod.dart';

final backendModeProvider = Provider<BackendMode>((ref) => BackendMode.local);

