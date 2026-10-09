import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço centralizado de gerenciamento e acesso ao Supabase Client (Seção 104).
abstract class SupabaseService {
  static SupabaseClient? _client;

  /// Retorna se o cliente foi inicializado
  static bool get isInitialized => _client != null;

  /// Retorna o cliente Supabase ativo.
  static SupabaseClient get client {
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
      } catch (_) {
        throw StateError('SupabaseService ainda não foi inicializado.');
      }
    }
    return _client!;
  }

  /// Inicializa o Supabase com as credenciais públicas.
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// Retorna o ID do usuário atualmente autenticado ou null se deslogado/não inicializado.
  static String? get currentUserId {
    if (!isInitialized) return null;
    try {
      return client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Retorna o email do usuário autenticado ou null se deslogado/não inicializado.
  static String? get currentUserEmail {
    if (!isInitialized) return null;
    try {
      return client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Stream reativo de mudanças de estado de autenticação.
  static Stream<AuthState>? get authStateChanges {
    if (!isInitialized) return null;
    return client.auth.onAuthStateChange;
  }
}
