import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'data/local_app_store.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase if environment variables are provided.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    // ignore: avoid_print
    print('Initializing Supabase client');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  final store = LocalAppStore();
  await store.hydrate();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWith((ref) => store),
      ],
      child: const TransportApp(),
    ),
  );
}
