import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_app_store.dart';
import '../../data/providers.dart';
import '../../data/repositories/store_change_stream.dart';
import '../models.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final LocalAppStore _store;

  @override
  AppUser? get currentUser => _store.user;

  @override
  bool get supportsRemotePasswordAuth => false;

  @override
  Stream<AppUser?> get userChanges =>
      storeChangeStream(_store, () => _store.user);

  @override
  Future<StoreResult> signInLocal({
    required String name,
    required UserRole role,
    String? assignedVehicleId,
  }) async {
    if (name.trim().isEmpty) {
      return const StoreResult.error('Informe o nome.');
    }
    _store.signIn(name: name, role: role, assignedVehicleId: assignedVehicleId);
    return const StoreResult.ok();
  }

  @override
  Future<StoreResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return const StoreResult.error(
      'Autenticação por e-mail está disponível apenas no modo Supabase.',
    );
  }

  @override
  Future<void> signOut() async {
    _store.signOut();
  }
}

final localAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository(ref.watch(localStoreProvider));
});
