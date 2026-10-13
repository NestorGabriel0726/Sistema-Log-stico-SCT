import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_logistics/app/app.dart';
import 'package:transport_logistics/features/auth/domain/entities/user_profile.dart';
import 'package:transport_logistics/features/auth/presentation/providers/auth_provider.dart';
import 'package:transport_logistics/features/auth/presentation/providers/auth_state.dart';
import 'package:transport_logistics/features/congregations/domain/entities/congregation.dart';

void main() {
  group('Smoke Tests e Roteamento Autenticado (Fase 1)', () {
    testWidgets('Usuário deslogado/inicial é direcionado para a tela de Login', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier.withState(const AuthStateUnauthenticated()),
            ),
          ],
          child: const TransportLogisticsApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gestão de Transporte'), findsOneWidget);
      expect(find.text('Entrar com Conta Google'), findsOneWidget);
    });

    testWidgets('Usuário autenticado e autorizado acessa a tela de Eventos de Transporte', (WidgetTester tester) async {
      final authorizedState = AuthStateAuthorized(
        profile: UserProfile(
          id: 'usr-1',
          email: 'coordenador@exemplo.com',
          fullName: 'Coordenador do Evento',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        activeCongregation: const Congregation(
          id: 'cong-1',
          name: 'Congregação Central',
          city: 'São Paulo',
          state: 'SP',
          countryCode: 'BR',
          currentUserRole: MemberRole.coordinator,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier.withState(authorizedState),
            ),
          ],
          child: const TransportLogisticsApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Eventos de Transporte'), findsOneWidget);
    });

    testWidgets('Usuário aguardando autorização visualiza tela de aviso', (WidgetTester tester) async {
      final pendingState = AuthStatePendingAuthorization(
        profile: UserProfile(
          id: 'usr-2',
          email: 'novo.usuario@exemplo.com',
          fullName: 'Novo Usuário',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              (ref) => AuthNotifier.withState(pendingState),
            ),
          ],
          child: const TransportLogisticsApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Acesso Aguardando Autorização'), findsOneWidget);
      expect(find.textContaining('novo.usuario@exemplo.com'), findsOneWidget);
    });
  });
}
