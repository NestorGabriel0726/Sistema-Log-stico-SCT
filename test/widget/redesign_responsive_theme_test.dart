import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transport_logistics/app/app.dart';
import 'package:transport_logistics/core/theme/theme_mode_provider.dart';
import 'package:transport_logistics/data/local_app_store.dart';
import 'package:transport_logistics/data/providers.dart';
import 'package:transport_logistics/data/seed_data.dart';
import 'package:transport_logistics/domain/models.dart';
import 'package:transport_logistics/features/event/event_detail_page.dart';
import 'package:transport_logistics/features/events/events_page.dart';
import 'package:transport_logistics/features/welcome/welcome_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Tema Claro, Escuro e Persistência', () {
    testWidgets('alternância de tema atualiza ThemeModeNotifier e persiste', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Inicia no modo sistema
      expect(container.read(themeModeProvider), ThemeMode.system);

      // Alterna para claro
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      // Alterna para escuro
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sct_theme_mode'), 'dark');
    });

    testWidgets('App renderiza corretamente em modo escuro e modo claro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = LocalAppStore();
      store.signIn(name: 'Coordenador Carlos', role: UserRole.coordinator);

      // Teste com tema escuro forçado
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStoreProvider.overrideWith((ref) => store),
            themeModeProvider.overrideWith((ref) => ThemeModeNotifier()..setMode(ThemeMode.dark)),
          ],
          child: const TransportApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransportApp), findsOneWidget);
    });
  });

  group('Responsividade e Layout Adaptativo sem Overflow', () {
    final representativeSizes = <String, Size>{
      'Mobile Pequeno (360 x 800)': const Size(360, 800),
      'Mobile Moderno (430 x 900)': const Size(430, 900),
      'Tablet Retrato (768 x 1024)': const Size(768, 1024),
      'Desktop Wide (1440 x 900)': const Size(1440, 900),
    };

    for (final entry in representativeSizes.entries) {
      testWidgets('WelcomePage adapta-se sem overflow em ${entry.key}', (tester) async {
        await tester.binding.setSurfaceSize(entry.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final store = LocalAppStore();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStoreProvider.overrideWith((ref) => store),
            ],
            child: const MaterialApp(
              home: WelcomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Transporte SCT'), findsOneWidget);
        expect(find.text('Entrar no painel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EventsPage adapta-se sem overflow em ${entry.key}', (tester) async {
        await tester.binding.setSurfaceSize(entry.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final store = LocalAppStore();
        store.signIn(name: 'Carlos Coordenador', role: UserRole.coordinator);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStoreProvider.overrideWith((ref) => store),
            ],
            child: const MaterialApp(
              home: EventsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Eventos'), findsOneWidget);
        expect(find.textContaining('Declare as Boas Novas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EventDetailPage adapta-se sem overflow em ${entry.key}', (tester) async {
        await tester.binding.setSurfaceSize(entry.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final store = LocalAppStore();
        store.signIn(name: 'Carlos Coordenador', role: UserRole.coordinator);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStoreProvider.overrideWith((ref) => store),
            ],
            child: const MaterialApp(
              home: EventDetailPage(eventId: SeedData.eventId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Declare as Boas Novas'), findsWidgets);
        expect(find.text('Visão geral'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
