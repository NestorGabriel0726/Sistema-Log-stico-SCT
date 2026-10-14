import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local_app_store.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
