// Abstract authentication repository
// Provides sign‑in/out and current user stream.

import '../models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthRepository {
  /// Returns the currently signed‑in user, or null if not authenticated.
  AppUser? get currentUser;

  /// Sign in using a name and role (local demo) – implementation will differ for Supabase.
  Future<void> signIn({required String name, required UserRole role, String? assignedVehicleId});

  /// Sign out the current user.
  Future<void> signOut();

  /// A Riverpod provider exposing the current user as a stream.
  /// Implementations should call `notifyListeners` on changes.
  Stream<AppUser?> get userChanges;
}

