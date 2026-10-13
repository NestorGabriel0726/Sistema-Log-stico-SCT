import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../../congregations/domain/entities/congregation.dart';
import '../../../invitations/domain/entities/invitation.dart';

/// Hierarquia tipada e imutável de estados de autenticação e autorização (Seções 12 e 13).
@immutable
sealed class AuthState {
  const AuthState();
}

/// Estado inicial enquanto verifica a persistência da sessão no dispositivo
class AuthStateInitializing extends AuthState {
  const AuthStateInitializing();
}

/// Usuário não está autenticado (sessão nula ou após logout)
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Carregando ou recuperando perfil do usuário autenticado
class AuthStateLoadingProfile extends AuthState {
  final String? email;
  const AuthStateLoadingProfile({this.email});
}

/// Usuário logou no Google, mas NÃO possui congregações nem convites pendentes
class AuthStatePendingAuthorization extends AuthState {
  final UserProfile profile;
  const AuthStatePendingAuthorization({required this.profile});
}

/// Usuário autenticado possui convites pendentes aguardando aceitação
class AuthStateHasPendingInvitations extends AuthState {
  final UserProfile profile;
  final List<Invitation> invitations;
  const AuthStateHasPendingInvitations({
    required this.profile,
    required this.invitations,
  });
}

/// Usuário autenticado pertence a múltiplas congregações e precisa escolher uma
class AuthStateSelectCongregation extends AuthState {
  final UserProfile profile;
  final List<Congregation> congregations;
  const AuthStateSelectCongregation({
    required this.profile,
    required this.congregations,
  });
}

/// Usuário totalmente autorizado com congregação ativa definida
class AuthStateAuthorized extends AuthState {
  final UserProfile profile;
  final Congregation activeCongregation;
  final List<Congregation> allCongregations;

  const AuthStateAuthorized({
    required this.profile,
    required this.activeCongregation,
    this.allCongregations = const [],
  });
}

/// Erro recuperável (ex: falha de rede ou cancelamento do Google OAuth)
class AuthStateRecoverableError extends AuthState {
  final String message;
  final String? code;
  final AuthState previousState;

  const AuthStateRecoverableError({
    required this.message,
    this.code,
    required this.previousState,
  });
}

/// Sessão expirou e requer novo login
class AuthStateSessionExpired extends AuthState {
  const AuthStateSessionExpired();
}
