import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização com Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: TransportLogisticsApp(),
    ),
  );
}
