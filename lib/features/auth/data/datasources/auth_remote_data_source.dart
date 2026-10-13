// ignore_for_file: prefer_initializing_formals
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/user_profile_model.dart';

abstract class AuthRemoteDataSource {
  Stream<AuthState> get onAuthStateChange;
  Session? get currentSession;
  User? get currentUser;
  Future<UserProfileModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserProfileModel> getProfile(String userId);
  Future<UserProfileModel> ensureProfile();
  Future<UserProfileModel> updateProfile(String userId, {required String fullName, String? avatarUrl});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required SupabaseClient client,
    GoogleSignIn? googleSignIn,
  })  : _client = client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: <String>['email', 'profile'],
            );

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<UserProfileModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Fluxo Web: PKCE OAuth com redirect
        final bool started = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'transportlogistics://login-callback',
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
        if (!started) {
          throw const AuthCancelledFailure('Início do fluxo Google OAuth cancelado pelo navegador.');
        }
        // Na Web, o browser pode redirecionar para a página do Google
        // Se já retornou autenticado ou sessão restaurada:
        final user = _client.auth.currentUser;
        if (user != null) {
          return await ensureProfile();
        }
        // Aguarda evento breve de autenticação ou retorna perfil atual
        return await _waitForUserSession();
      } else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Fluxo Mobile Nativo via GoogleSignIn
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw const AuthCancelledFailure('Login com o Google cancelado pelo usuário.');
          }

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final String? idToken = googleAuth.idToken;
          final String? accessToken = googleAuth.accessToken;

          if (idToken == null && accessToken == null) {
            throw const AuthFailure('Não foi possível obter as credenciais do Google.');
          }

          final AuthResponse res = await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken ?? '',
            accessToken: accessToken,
          );

          if (res.user == null) {
            throw const AuthFailure('Falha ao autenticar usuário no Supabase.');
          }

          return await ensureProfile();
        } catch (nativeError) {
          if (nativeError is AuthCancelledFailure) rethrow;
          // Fallback para OAuth via navegador móvel se o plugin nativo não tiver client-id configurado localmente
          final bool started = await _client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'transportlogistics://login-callback',
          );
          if (!started) {
            throw const AuthCancelledFailure('Login cancelado.');
          }
          return await _waitForUserSession();
        }
      } else {
        // Desktop (Windows / macOS / Linux)
        final bool started = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'transportlogistics://login-callback',
        );
        if (!started) {
          throw const AuthCancelledFailure('Login cancelado.');
        }
        return await _waitForUserSession();
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('cancel')) {
        throw const AuthCancelledFailure();
      }
      throw AuthFailure(e.message, e.statusCode);
    } on Failure {
      rethrow;
    } catch (e) {
      if (e.toString().toLowerCase().contains('cancel') || e.toString().contains('aborted')) {
        throw const AuthCancelledFailure();
      }
      throw AuthFailure('Não foi possível completar o login: ${e.toString()}');
    }
  }

  Future<UserProfileModel> _waitForUserSession() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      return await ensureProfile();
    }
    // Aguarda até 3 segundos pela sessão caso esteja completando handshake
    try {
      final authEvent = await _client.auth.onAuthStateChange
          .firstWhere((event) => event.session != null)
          .timeout(const Duration(seconds: 4));
      if (authEvent.session != null) {
        return await ensureProfile();
      }
    } catch (_) {
      // Timeout normal se o redirect estiver navegando fora
    }

    final fallbackUser = _client.auth.currentUser;
    if (fallbackUser != null) {
      return await ensureProfile();
    }
    throw const AuthFailure('Aguardando conclusão do login no navegador.');
  }

  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      await _client.auth.signOut();
    } catch (e) {
      throw AuthFailure('Erro ao encerrar a sessão: $e');
    }
  }

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res == null) {
        // Perfil ainda não sincronizado: garantir via RPC
        return await ensureProfile();
      }

      return UserProfileModel.fromJson(res);
    } catch (e) {
      // Fallback para ensureProfile
      return await ensureProfile();
    }
  }

  @override
  Future<UserProfileModel> ensureProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Nenhum usuário autenticado.');
    }

    try {
      // Chama a Database RPC function idempotente
      final res = await _client.rpc('ensure_profile_exists');
      if (res != null && res is Map<String, dynamic>) {
        return UserProfileModel.fromJson(res);
      }
    } catch (_) {
      // Fallback para query direta na tabela se a RPC não estiver disponível
    }

    try {
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        return UserProfileModel.fromJson(existing);
      }

      // Inserção direta de fallback
      final email = user.email ?? '';
      final fullName = (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          (email.contains('@') ? email.split('@').first : '');
      final avatarUrl = (user.userMetadata?['avatar_url'] as String?) ??
          (user.userMetadata?['picture'] as String?);

      final insertRes = await _client
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': email.toLowerCase().trim(),
            'full_name': fullName,
            'avatar_url': avatarUrl,
          })
          .select()
          .single();

      return UserProfileModel.fromJson(insertRes);
    } catch (e) {
      throw AuthFailure('Não foi possível carregar o perfil de usuário: $e');
    }
  }

  @override
  Future<UserProfileModel> updateProfile(
    String userId, {
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      final res = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserProfileModel.fromJson(res);
    } catch (e) {
      throw DomainFailure('Erro ao atualizar dados do perfil: $e');
    }
  }
}
