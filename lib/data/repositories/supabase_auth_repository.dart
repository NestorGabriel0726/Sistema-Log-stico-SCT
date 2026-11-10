import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/repositories/auth_repository.dart';
import 'supabase_error_mapper.dart';
import 'supabase_mappers.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  AppUser? _cached;

  @override
  AppUser? get currentUser => _cached;

  @override
  bool get supportsRemotePasswordAuth => true;

  @override
  Stream<AppUser?> get userChanges async* {
    yield await _hydrate();
    await for (final auth in _client.auth.onAuthStateChange) {
      if (auth.session == null) {
        _cached = null;
        yield null;
      } else {
        yield await _hydrate();
      }
    }
  }

  @override
  Future<StoreResult> signInLocal({
    required String name,
    required UserRole role,
    String? assignedVehicleId,
  }) async {
    return const StoreResult.error(
      'O modo colaborativo exige e-mail e senha da conta real. '
      'Não utilize perfis fictícios no backend remoto.',
    );
  }

  @override
  Future<StoreResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null || response.user == null) {
        return const StoreResult.error('Não foi possível autenticar.');
      }
      await _hydrate();
      if (_cached == null) {
        await _client.auth.signOut();
        return const StoreResult.error(
          'Conta autenticada, mas sem perfil ou vínculo de congregação.',
        );
      }
      return const StoreResult.ok();
    } on AuthException catch (e) {
      return StoreResult.error(e.message);
    } catch (e) {
      return mapSupabaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _cached = null;
  }

  Future<AppUser?> _hydrate() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _cached = null;
      return null;
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final staff = await _client
        .from('event_staff')
        .select('role, assigned_vehicle_id')
        .eq('user_id', user.id);

    final memberships = await _client
        .from('congregation_members')
        .select('role')
        .eq('user_id', user.id)
        .eq('status', 'ACTIVE');

    final roles = <UserRole>[];
    String? assignedVehicleId;
    if (staff is List) {
      for (final row in staff) {
        if (row is Map) {
          roles.add(userRoleFromStaff(row['role']));
          assignedVehicleId ??= row['assigned_vehicle_id'] as String?;
        }
      }
    }
    if (memberships is List) {
      for (final row in memberships) {
        if (row is Map && '${row['role']}'.toUpperCase() == 'COORDINATOR') {
          roles.add(UserRole.coordinator);
        }
      }
    }

    final name = profile == null
        ? (user.email ?? 'Usuário')
        : '${profile['full_name'] ?? user.email ?? 'Usuário'}';

    _cached = AppUser(
      id: user.id,
      name: name.isEmpty ? (user.email ?? 'Usuário') : name,
      email: user.email ?? '${profile?['email'] ?? ''}',
      role: roles.isEmpty ? UserRole.captainHelper : strongestRole(roles),
      assignedVehicleId: assignedVehicleId,
    );
    return _cached;
  }
}
