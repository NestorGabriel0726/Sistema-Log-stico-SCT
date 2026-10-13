import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/auth_state.dart'
    as app_auth_state;
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/pending_approval_page.dart';
import '../features/auth/presentation/pages/pending_invitations_page.dart';
import '../features/congregations/presentation/pages/select_congregation_page.dart';
import '../features/events/presentation/pages/events_list_page.dart';
import '../features/events/presentation/pages/event_detail_page.dart';

/// Chave global do navegador
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifier que reage às mudanças de [AuthState] para atualizar o [GoRouter] (Seção 8 e 13).
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<app_auth_state.AuthState>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final location = state.matchedLocation;

    final isLogin = location == '/login';
    final isPendingApproval = location == '/pending-approval';
    final isPendingInvitations = location == '/pending-invitations';
    final isSelectCongregation = location == '/select-congregation';

    final isAuthRoute = isLogin || isPendingApproval || isPendingInvitations || isSelectCongregation;

    // 1. Inicializando ou Carregando Perfil: mantém o usuário na tela atual
    if (authState is app_auth_state.AuthStateInitializing ||
        authState is app_auth_state.AuthStateLoadingProfile) {
      return null;
    }

    // 2. Não autenticado ou Sessão expirada: redireciona para login
    if (authState is app_auth_state.AuthStateUnauthenticated ||
        authState is app_auth_state.AuthStateSessionExpired) {
      return isLogin ? null : '/login';
    }

    // 3. Usuário autenticado mas sem congregações nem convites: aguardando autorização (Seção 8)
    if (authState is app_auth_state.AuthStatePendingAuthorization) {
      return isPendingApproval ? null : '/pending-approval';
    }

    // 4. Usuário autenticado com convites pendentes: tela de aceite de convites
    if (authState is app_auth_state.AuthStateHasPendingInvitations) {
      return isPendingInvitations ? null : '/pending-invitations';
    }

    // 5. Múltiplas congregações: seleção da congregação ativa
    if (authState is app_auth_state.AuthStateSelectCongregation) {
      return isSelectCongregation ? null : '/select-congregation';
    }

    // 6. Usuário autorizado com congregação ativa: rotas protegidas liberadas
    if (authState is app_auth_state.AuthStateAuthorized) {
      if (isAuthRoute) {
        return '/events';
      }
      return null;
    }

    // 7. Erro recuperável
    if (authState is app_auth_state.AuthStateRecoverableError) {
      if (authState.previousState is app_auth_state.AuthStateUnauthenticated) {
        return isLogin ? null : '/login';
      }
      return null;
    }

    return null;
  }
}

/// Provider do [GoRouter] integrado com Riverpod e protegido por [AuthState]
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: _routes,
  );
});

final List<RouteBase> _routes = <RouteBase>[
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (BuildContext context, GoRouterState state) => const LoginPage(),
  ),
  GoRoute(
    path: '/pending-approval',
    name: 'pending-approval',
    builder: (BuildContext context, GoRouterState state) =>
        const PendingApprovalPage(),
  ),
  GoRoute(
    path: '/pending-invitations',
    name: 'pending-invitations',
    builder: (BuildContext context, GoRouterState state) =>
        const PendingInvitationsPage(),
  ),
  GoRoute(
    path: '/select-congregation',
    name: 'select-congregation',
    builder: (BuildContext context, GoRouterState state) =>
        const SelectCongregationPage(),
  ),
  GoRoute(
    path: '/events',
    name: 'events',
    builder: (BuildContext context, GoRouterState state) =>
        const EventsListPage(),
    routes: <RouteBase>[
      GoRoute(
        path: ':id',
        name: 'event-detail',
        builder: (BuildContext context, GoRouterState state) {
          final String eventId = state.pathParameters['id'] ?? '';
          return EventDetailPage(eventId: eventId);
        },
      ),
    ],
  ),
];

/// Instância padrão do GoRouter para compatibilidade retroativa
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  routes: _routes,
);
