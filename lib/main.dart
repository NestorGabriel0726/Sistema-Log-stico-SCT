import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega credenciais públicas do Supabase via --dart-define com fallback para ambiente de desenvolvimento local
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_development',
  );

  try {
    await SupabaseService.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Aviso: Falha ao inicializar SupabaseService: $e');
    }
  }

  // Inicialização com Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: TransportLogisticsApp(),
    ),
  );
}
