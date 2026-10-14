import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transport_logistics/app/app.dart';

void main() {
  testWidgets('Fluxo local: welcome e painel de eventos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(const ProviderScope(child: TransportApp()));
    await tester.pumpAndSettle();

    expect(find.text('Transporte SCT'), findsOneWidget);
    expect(find.text('Entrar no painel'), findsOneWidget);

    await tester.ensureVisible(find.text('Entrar no painel'));
    await tester.tap(find.text('Entrar no painel'));
    await tester.pumpAndSettle();

    expect(find.text('Eventos'), findsOneWidget);
    expect(find.textContaining('Declare as Boas Novas'), findsOneWidget);
  });
}
