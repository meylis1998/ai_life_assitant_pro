import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../injection_container.dart' as di;

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/welcome',

    // Listen to auth state changes and refresh routes
    refreshListenable: GoRouterRefreshStream(
      di.sl<AuthBloc>().stream,
    ),

    redirect: (BuildContext context, GoRouterState state) {
      final authState = di.sl<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;

      final isGoingToAuth = state.matchedLocation == '/auth';
      final isGoingToWelcome = state.matchedLocation == '/welcome';

      // If not authenticated and trying to access protected routes, go to welcome
      if (!isAuthenticated && !isGoingToAuth && !isGoingToWelcome) {
        return '/welcome';
      }

      // If authenticated and on auth/welcome pages, go to chat
      if (isAuthenticated && (isGoingToAuth || isGoingToWelcome)) {
        return '/chat';
      }

      // No redirect needed
      return null;
    },

    routes: [
      // Welcome/Onboarding Route
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const WelcomePage(),
        ),
      ),

      // Authentication Route
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AuthPage(),
        ),
      ),

      // Chat Route (Protected)
      GoRoute(
        path: '/chat',
        name: 'chat',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ChatPage(),
        ),
      ),

      // Settings Route (Protected)
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsPage(),
        ),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

/// Helper class to refresh GoRouter when stream emits
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
