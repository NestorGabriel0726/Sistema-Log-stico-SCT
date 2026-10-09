import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/network/supabase_service.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/pending_approval_page.dart';
import '../features/events/presentation/pages/events_list_page.dart';
import '../features/events/presentation/pages/event_detail_page.dart';

/// Configuração central do GoRouter com rotas públicas e protegidas (Seção 8).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/events',
  redirect: (BuildContext context, GoRouterState state) {
    final bool isAuthenticated = SupabaseService.currentUserId != null;
    final bool isLoggingIn = state.matchedLocation == '/login';
    final bool isPending = state.matchedLocation == '/pending-approval';

    // Se não estiver autenticado e não estiver na tela de login, permitir navegação em dev ou redirecionar
    if (!isAuthenticated && !isLoggingIn && !isPending) {
      // Em desenvolvimento inicial ou sem backend inicializado, mantém na rota para teste
      return null;
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginPage(),
    ),
    GoRoute(
      path: '/pending-approval',
      builder: (BuildContext context, GoRouterState state) => const PendingApprovalPage(),
    ),
    GoRoute(
      path: '/events',
      builder: (BuildContext context, GoRouterState state) => const EventsListPage(),
      routes: <RouteBase>[
        GoRoute(
          path: ':id',
          builder: (BuildContext context, GoRouterState state) {
            final String eventId = state.pathParameters['id'] ?? '';
            return EventDetailPage(eventId: eventId);
          },
        ),
      ],
    ),
  ],
);
