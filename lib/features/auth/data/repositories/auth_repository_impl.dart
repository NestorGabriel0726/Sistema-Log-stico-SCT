import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StreamController<UserProfile?> _profileStreamController =
      StreamController<UserProfile?>.broadcast();

  UserProfile? _cachedProfile;
  StreamSubscription<AuthState>? _authSubscription;

  AuthRepositoryImpl({required this._remoteDataSource}) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _remoteDataSource.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _cachedProfile = null;
        _profileStreamController.add(null);
      } else {
        try {
          final profile = await _remoteDataSource.getProfile(session.user.id);
          _cachedProfile = profile;
          _profileStreamController.add(profile);
        } catch (_) {
          // Em caso de erro temporário de rede, mantém stream notificado com o id disponível
          if (_cachedProfile?.id != session.user.id) {
            _cachedProfile = UserProfile(
              id: session.user.id,
              email: session.user.email ?? '',
              fullName: (session.user.userMetadata?['full_name'] as String?) ??
                  (session.user.userMetadata?['name'] as String?) ??
                  '',
              avatarUrl: session.user.userMetadata?['avatar_url'] as String?,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _profileStreamController.add(_cachedProfile);
          }
        }
      }
    });
  }

  @override
  Stream<UserProfile?> get authProfileChanges => _profileStreamController.stream;

  @override
  UserProfile? get currentUserProfile => _cachedProfile;

  @override
  String? get currentUserId => _remoteDataSource.currentUser?.id;

  @override
  String? get currentUserEmail => _remoteDataSource.currentUser?.email;

  @override
  bool get isAuthenticated => _remoteDataSource.currentSession != null;

  @override
  Future<UserProfile> signInWithGoogle() async {
    final profile = await _remoteDataSource.signInWithGoogle();
    _cachedProfile = profile;
    _profileStreamController.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    _cachedProfile = null;
    _profileStreamController.add(null);
  }

  @override
  Future<UserProfile> ensureProfile() async {
    final profile = await _remoteDataSource.ensureProfile();
    _cachedProfile = profile;
    _profileStreamController.add(profile);
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final currentId = currentUserId;
    if (currentId == null) {
      throw StateError('Usuário não autenticado');
    }
    final updated = await _remoteDataSource.updateProfile(
      currentId,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
    _cachedProfile = updated;
    _profileStreamController.add(updated);
    return updated;
  }

  void dispose() {
    _authSubscription?.cancel();
    _profileStreamController.close();
  }
}
