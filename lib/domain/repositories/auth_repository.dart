import '../models.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> get userChanges;

  bool get supportsRemotePasswordAuth;

  /// Demo / local identification used by the welcome screen.
  Future<StoreResult> signInLocal({
    required String name,
    required UserRole role,
    String? assignedVehicleId,
  });

  /// Supabase Auth. Must not be used with hardcoded demo passwords.
  Future<StoreResult> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
