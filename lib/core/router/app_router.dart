import 'dart:async';

import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';
import 'package:financo/features/auth/presentation/pages/auth_page.dart';
import 'package:financo/features/home/presentation/pages/app_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using go_router.
/// 
/// Handles navigation and authentication-based redirects throughout the app.
/// Redirects unauthenticated users to the auth page and authenticated users
/// to the app shell.
class AppRouter {
  static const String authRoute = '/auth';
  static const String homeRoute = '/';

  /// Creates and configures the GoRouter instance.
  /// 
  /// The router listens to authentication state changes and automatically
  /// redirects users based on their authentication status.
  static GoRouter createRouter() {
    final authBloc = sl<AuthBloc>();

    return GoRouter(
      initialLocation: authRoute,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final isAuthRoute = state.matchedLocation == authRoute;

        // If user is authenticated and on auth page, redirect to home
        if (authState is Authenticated && isAuthRoute) {
          return homeRoute;
        }

        // If user is not authenticated and not on auth page, redirect to auth
        if (authState is Unauthenticated && !isAuthRoute) {
          return authRoute;
        }

        // If loading or error, stay on current page
        if (authState is AuthLoading || authState is AuthError) {
          return null;
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          path: authRoute,
          name: 'auth',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const AuthPage(),
          ),
        ),
        GoRoute(
          path: homeRoute,
          name: 'home',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const AppShellPage(),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );
  }
}

/// Helper class to convert a Stream into a Listenable for GoRouter.
/// 
/// This allows GoRouter to react to authentication state changes
/// and trigger redirects automatically.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
