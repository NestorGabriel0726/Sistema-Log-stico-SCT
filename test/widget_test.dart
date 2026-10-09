import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_logistics/app/app.dart';

void main() {
  testWidgets('Smoke test da aplicação e renderização inicial', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TransportLogisticsApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifica se a tela inicial de eventos foi renderizada
    expect(find.text('Eventos de Transporte'), findsOneWidget);
  });
}
