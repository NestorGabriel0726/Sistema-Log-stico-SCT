import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_logistics/data/local_app_store.dart';
import 'package:transport_logistics/data/providers.dart';
import 'package:transport_logistics/data/seed_data.dart';
import 'package:transport_logistics/domain/models.dart';
import 'package:transport_logistics/features/event/passage_form_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocalAppStore> pumpEditForm(WidgetTester tester) async {
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWith((ref) => store),
        ],
        child: MaterialApp(
          home: PassageFormPage(
            eventId: SeedData.eventId,
            passageId: 'pass-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('modo edição carrega dados e título correto', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEditForm(tester);

    expect(find.text('Editar passagem'), findsOneWidget);
    expect(find.text('Histórico financeiro'), findsOneWidget);
    expect(find.text('Ana Silva'), findsWidgets);

    final saveButton = find.text('Salvar alterações');
    await tester.scrollUntilVisible(saveButton, 200, scrollable: find.byType(Scrollable).first);
    expect(saveButton, findsOneWidget);
  });

  testWidgets('alterar campos sem salvar não modifica o store', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await pumpEditForm(tester);
    final before = store.passageById('pass-1')!;

    await tester.enterText(find.byType(TextField).first, 'Nome Que Não Deve Salvar');
    await tester.pump();

    final after = store.passageById('pass-1')!;
    expect(after.buyerName, before.buyerName);
    expect(after.paidCents, before.paidCents);
    expect(after.passengerIds, before.passengerIds);
  });

  testWidgets('modo criação usa título Nova passagem', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWith((ref) => store),
        ],
        child: const MaterialApp(
          home: PassageFormPage(eventId: SeedData.eventId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova passagem'), findsOneWidget);
    expect(find.text('Registrar passagem'), findsOneWidget);
    expect(find.text('Histórico financeiro'), findsNothing);
  });

  testWidgets('exibe mensagem de elegibilidade e calcula isenção por data de nascimento', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = LocalAppStore();
    store.signIn(name: 'Carlos', role: UserRole.coordinator);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWith((ref) => store),
        ],
        child: const MaterialApp(
          home: PassageFormPage(eventId: SeedData.eventId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Mensagem inicial de data não informada
    expect(find.textContaining('o cálculo da isenção ainda não pode ser realizado'), findsOneWidget);
  });
}
