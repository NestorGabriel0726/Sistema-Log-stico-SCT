// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../congregations/data/datasources/congregations_remote_data_source.dart';
import '../../../congregations/data/models/congregation_model.dart';
import '../../../congregations/data/repositories/congregations_repository_impl.dart';
import '../../../congregations/domain/entities/congregation.dart';
import '../../../congregations/domain/repositories/congregations_repository.dart';
import '../../../invitations/data/datasources/invitations_remote_data_source.dart';
import '../../../invitations/data/models/invitation_model.dart';
import '../../../invitations/data/repositories/invitations_repository_impl.dart';
import '../../../invitations/domain/entities/invitation.dart';
import '../../../invitations/domain/repositories/invitations_repository.dart';
import 'auth_state.dart';

// --- DATA SOURCE & REPOSITORY PROVIDERS ---

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (!SupabaseService.isInitialized) {
    return _OfflineAuthRemoteDataSource();
  }
  return AuthRemoteDataSourceImpl(client: SupabaseService.client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  final repo = AuthRepositoryImpl(remoteDataSource: dataSource);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final congregationsRemoteDataSourceProvider = Provider<CongregationsRemoteDataSource>((ref) {
  if (!SupabaseService.isInitialized) {
    return _OfflineCongregationsRemoteDataSource();
  }
  return CongregationsRemoteDataSourceImpl(client: SupabaseService.client);
});

final congregationsRepositoryProvider = Provider<CongregationsRepository>((ref) {
  final dataSource = ref.watch(congregationsRemoteDataSourceProvider);
  return CongregationsRepositoryImpl(remoteDataSource: dataSource);
});

final invitationsRemoteDataSourceProvider = Provider<InvitationsRemoteDataSource>((ref) {
  if (!SupabaseService.isInitialized) {
    return _OfflineInvitationsRemoteDataSource();
  }
  return InvitationsRemoteDataSourceImpl(client: SupabaseService.client);
});

final invitationsRepositoryProvider = Provider<InvitationsRepository>((ref) {
  final dataSource = ref.watch(invitationsRemoteDataSourceProvider);
  return InvitationsRepositoryImpl(remoteDataSource: dataSource);
});

// --- AUTH STATE NOTIFIER PROVIDER ---

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final congRepo = ref.watch(congregationsRepositoryProvider);
  final invRepo = ref.watch(invitationsRepositoryProvider);

  return AuthNotifier(
    authRepository: authRepo,
    congregationsRepository: congRepo,
    invitationsRepository: invRepo,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final CongregationsRepository _congregationsRepository;
  final InvitationsRepository _invitationsRepository;
  StreamSubscription? _authSub;

  AuthNotifier({
    required AuthRepository authRepository,
    required CongregationsRepository congregationsRepository,
    required InvitationsRepository invitationsRepository,
  })  : _authRepository = authRepository,
        _congregationsRepository = congregationsRepository,
        _invitationsRepository = invitationsRepository,
        super(const AuthStateInitializing()) {
    _init();
  }

  /// Construtor de teste para injetar estado de autenticação pré-definido
  AuthNotifier.withState(
    super.initialState, {
    AuthRepository? authRepository,
    CongregationsRepository? congregationsRepository,
    InvitationsRepository? invitationsRepository,
  })  : _authRepository = authRepository ?? _EmptyAuthRepository(),
        _congregationsRepository = congregationsRepository ?? _EmptyCongregationsRepository(),
        _invitationsRepository = invitationsRepository ?? _EmptyInvitationsRepository();

  void _init() {
    _authSub = _authRepository.authProfileChanges.listen((profile) async {
      if (profile == null) {
        if (state is! AuthStateUnauthenticated) {
          state = const AuthStateUnauthenticated();
        }
      } else {
        await refreshUserStatus();
      }
    });

    // Verificação inicial da sessão persistida
    if (_authRepository.isAuthenticated) {
      refreshUserStatus();
    } else {
      state = const AuthStateUnauthenticated();
    }
  }

  /// Recarrega o perfil, memberships e convites do usuário autenticado
  Future<void> refreshUserStatus() async {
    final currentProfile = _authRepository.currentUserProfile;
    final email = _authRepository.currentUserEmail;

    if (!_authRepository.isAuthenticated) {
      state = const AuthStateUnauthenticated();
      return;
    }

    state = AuthStateLoadingProfile(email: email);

    try {
      final profile = currentProfile ?? await _authRepository.ensureProfile();

      // 1. Obter congregações ativas do usuário
      final congregations = await _congregationsRepository.getMyCongregations();

      if (congregations.length == 1) {
        // Seleção automática da única congregação autorizada (Seção 5)
        final singleCongregation = congregations.first;
        _congregationsRepository.setActiveCongregation(singleCongregation);
        state = AuthStateAuthorized(
          profile: profile,
          activeCongregation: singleCongregation,
          allCongregations: congregations,
        );
        return;
      } else if (congregations.length > 1) {
        // Múltiplas congregações: verificar se já possui uma ativa definida
        final active = _congregationsRepository.activeCongregation;
        if (active != null && congregations.any((c) => c.id == active.id)) {
          state = AuthStateAuthorized(
            profile: profile,
            activeCongregation: active,
            allCongregations: congregations,
          );
        } else {
          state = AuthStateSelectCongregation(
            profile: profile,
            congregations: congregations,
          );
        }
        return;
      }

      // 2. Nenhuma congregação ativa: verificar se há convites pendentes
      final pendingInvitations = await _invitationsRepository.getMyPendingInvitations();

      if (pendingInvitations.isNotEmpty) {
        state = AuthStateHasPendingInvitations(
          profile: profile,
          invitations: pendingInvitations,
        );
        return;
      }

      // 3. Nenhuma congregação e nenhum convite: Usuário aguardando autorização (Seção 8)
      state = AuthStatePendingAuthorization(profile: profile);
    } catch (e) {
      if (e is AuthFailure && e.code == 'AUTH_ERROR') {
        state = const AuthStateSessionExpired();
      } else {
        state = AuthStateRecoverableError(
          message: e.toString(),
          previousState: state,
        );
      }
    }
  }

  /// Inicia fluxo de login com Google
  Future<void> signInWithGoogle() async {
    final previousState = state;
    state = const AuthStateLoadingProfile();

    try {
      await _authRepository.signInWithGoogle();
      await refreshUserStatus();
    } on AuthCancelledFailure {
      // Cancelamento tratado sem apresentar erro crítico
      state = previousState is AuthStateUnauthenticated
          ? const AuthStateUnauthenticated()
          : previousState;
    } catch (e) {
      state = AuthStateRecoverableError(
        message: e is Failure ? e.message : 'Falha ao autenticar com o Google.',
        code: e is Failure ? e.code : null,
        previousState: const AuthStateUnauthenticated(),
      );
    }
  }

  /// Seleciona uma congregação ativa (quando o usuário pertence a mais de uma)
  void selectCongregation(Congregation congregation) {
    _congregationsRepository.setActiveCongregation(congregation);
    final profile = _authRepository.currentUserProfile;
    if (profile != null) {
      state = AuthStateAuthorized(
        profile: profile,
        activeCongregation: congregation,
      );
    }
  }

  /// Aceita um convite atômico validado pelo backend
  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _invitationsRepository.acceptInvitation(invitationId);
      await refreshUserStatus();
    } catch (e) {
      final msg = e is Failure ? e.message : e.toString();
      state = AuthStateRecoverableError(
        message: msg,
        previousState: state,
      );
    }
  }

  /// Logout seguro
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _congregationsRepository.clearActiveCongregation();
      state = const AuthStateUnauthenticated();
    } catch (e) {
      state = const AuthStateUnauthenticated();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// --- REPOSITÓRIOS E DATASOURCES DE FALLBACK PARA TESTES E MODO OFFLINE ---

class _EmptyAuthRepository implements AuthRepository {
  @override
  Stream<UserProfile?> get authProfileChanges => const Stream.empty();
  @override
  String? get currentUserEmail => null;
  @override
  String? get currentUserId => null;
  @override
  UserProfile? get currentUserProfile => null;
  @override
  bool get isAuthenticated => false;
  @override
  Future<UserProfile> ensureProfile() async => throw UnimplementedError();
  @override
  Future<UserProfile> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<UserProfile> updateProfile({required String fullName, String? avatarUrl}) async =>
      throw UnimplementedError();
}

class _EmptyCongregationsRepository implements CongregationsRepository {
  Congregation? _active;
  @override
  Congregation? get activeCongregation => _active;
  @override
  void clearActiveCongregation() => _active = null;
  @override
  void setActiveCongregation(Congregation congregation) => _active = congregation;
  @override
  Future<Congregation?> getCongregationById(String id) async => null;
  @override
  Future<List<Congregation>> getMyCongregations() async => [];
}

class _EmptyInvitationsRepository implements InvitationsRepository {
  @override
  Future<void> acceptInvitation(String invitationId) async {}
  @override
  Future<Invitation> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays = 7,
  }) async => throw UnimplementedError();
  @override
  Future<List<Invitation>> getMyPendingInvitations() async => [];
  @override
  Future<void> revokeInvitation(String invitationId) async {}
}

class _OfflineAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  supabase.Session? get currentSession => null;
  @override
  supabase.User? get currentUser => null;
  @override
  Stream<supabase.AuthState> get onAuthStateChange => const Stream.empty();
  @override
  Future<UserProfileModel> ensureProfile() async => throw const AuthFailure('Supabase não inicializado.');
  @override
  Future<UserProfileModel> getProfile(String userId) async => throw const AuthFailure('Supabase não inicializado.');
  @override
  Future<UserProfileModel> signInWithGoogle() async => throw const AuthFailure('Supabase não inicializado.');
  @override
  Future<void> signOut() async {}
  @override
  Future<UserProfileModel> updateProfile(String userId, {required String fullName, String? avatarUrl}) async =>
      throw const AuthFailure('Supabase não inicializado.');
}

class _OfflineCongregationsRemoteDataSource implements CongregationsRemoteDataSource {
  @override
  Future<CongregationModel?> getCongregationById(String id) async => null;
  @override
  Future<List<CongregationModel>> getMyCongregations() async => [];
}

class _OfflineInvitationsRemoteDataSource implements InvitationsRemoteDataSource {
  @override
  Future<void> acceptInvitation(String invitationId) async {}
  @override
  Future<InvitationModel> createInvitation({
    required String email,
    required String congregationId,
    String? eventId,
    required InvitationRole role,
    String? assignedVehicleId,
    int expiresInDays = 7,
  }) async => throw const AuthFailure('Supabase não inicializado.');
  @override
  Future<List<InvitationModel>> getMyPendingInvitations() async => [];
  @override
  Future<void> revokeInvitation(String invitationId) async {}
}
