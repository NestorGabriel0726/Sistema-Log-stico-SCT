import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/event/event_detail_page.dart';
import '../features/events/events_page.dart';
import '../features/welcome/welcome_page.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(localStoreProvider).user;
      final onWelcome = state.matchedLocation == '/';

      if (user == null && !onWelcome) return '/';
      if (user != null && onWelcome) return '/events';
      return null;
    },
    refreshListenable: _RouterRefresh(ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const WelcomePage(),
      ),
      GoRoute(
        path: '/events',
        builder: (_, __) => const EventsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return EventDetailPage(eventId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(localStoreProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
