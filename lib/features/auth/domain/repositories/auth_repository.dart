import '../entities/user_profile.dart';

/// Contrato abstrato do repositório de autenticação e perfis.
abstract class AuthRepository {
  /// Stream reativo emitindo o perfil atual ou null quando deslogado
  Stream<UserProfile?> get authProfileChanges;

  /// Retorna o perfil atual em cache na memória, se autenticado
  UserProfile? get currentUserProfile;

  /// Retorna o identificador auth.users.id atual
  String? get currentUserId;

  /// Retorna o e-mail autenticado
  String? get currentUserEmail;

  /// Verifica se há uma sessão ativa
  bool get isAuthenticated;

  /// Inicia o fluxo de autenticação com o Google OAuth
  Future<UserProfile> signInWithGoogle();

  /// Encerra a sessão atual
  Future<void> signOut();

  /// Garante a existência do perfil de forma idempotente via banco
  Future<UserProfile> ensureProfile();

  /// Atualiza dados cadastrais não-privilegiados do próprio perfil
  Future<UserProfile> updateProfile({
    required String fullName,
    String? avatarUrl,
  });
}
