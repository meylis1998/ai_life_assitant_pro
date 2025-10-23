import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/ai_chat/presentation/pages/chat_page.dart';
import '../../features/daily_briefing/presentation/pages/briefing_page.dart';
import '../../injection_container.dart' as di;
import 'scaffold_with_nav_bar.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorBriefingKey = GlobalKey<NavigatorState>(
    debugLabel: 'shellBriefing',
  );
  static final _shellNavigatorChatKey = GlobalKey<NavigatorState>(
    debugLabel: 'shellChat',
  );
  static final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(
    debugLabel: 'shellSettings',
  );

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/welcome',

    // Listen to auth state changes and refresh routes
    refreshListenable: GoRouterRefreshStream(di.sl<AuthBloc>().stream),

    redirect: (BuildContext context, GoRouterState state) {
      final authState = di.sl<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;

      final isGoingToAuth = state.matchedLocation == '/auth';
      final isGoingToWelcome = state.matchedLocation == '/welcome';

      // If not authenticated and trying to access protected routes, go to welcome
      if (!isAuthenticated && !isGoingToAuth && !isGoingToWelcome) {
        return '/welcome';
      }

      // If authenticated and on auth/welcome pages, go to briefing
      if (isAuthenticated && (isGoingToAuth || isGoingToWelcome)) {
        return '/briefing';
      }

      // No redirect needed
      return null;
    },

    routes: [
      // Welcome/Onboarding Route
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const WelcomePage()),
      ),

      // Authentication Route
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SignInPage()),
      ),

      // Main app with bottom navigation (Protected)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Briefing branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorBriefingKey,
            routes: [
              GoRoute(
                path: '/briefing',
                name: 'briefing',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BriefingPage()),
              ),
            ],
          ),

          // Chat branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChatKey,
            routes: [
              GoRoute(
                path: '/chat',
                name: 'chat',
                pageBuilder: (context, state) =>
                    NoTransitionPage(child: ChatPage()),
              ),
            ],
          ),

          // Settings branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsPage()),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}

/// Helper class to refresh GoRouter when stream emits
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
