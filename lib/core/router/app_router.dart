import 'dart:async';

import 'package:financo/core/widgets/security_gate.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';
import 'package:financo/features/auth/presentation/pages/auth_page.dart';
import 'package:financo/features/auth/presentation/pages/onboarding_page.dart';
import 'package:financo/core/subscription/presentation/pages/paywall_page.dart';
import 'package:financo/features/auth/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application router configuration using go_router.
///
/// Handles navigation and authentication-based redirects throughout the app.
/// Redirects unauthenticated users to the auth page and authenticated users
/// to the app shell.
class AppRouter {
  static const String authRoute = '/auth';
  static const String homeRoute = '/';
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String paywallRoute = '/paywall';

  /// Creates and configures the GoRouter instance.
  ///
  /// The router listens to authentication state changes and automatically
  /// redirects users based on their authentication status.
  static GoRouter createRouter() {
    final authBloc = sl<AuthBloc>();

    return GoRouter(
      initialLocation: splashRoute,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        try {
          final authState = authBloc.state;
          final prefs = sl<SharedPreferences>();
          final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

          final isSplashRoute = state.matchedLocation == splashRoute;
          final isAuthRoute = state.matchedLocation == authRoute;
          final isOnboardingRoute = state.matchedLocation == onboardingRoute;

          // If auth is still initializing, show splash
          if (authState is AuthInitial || authState is AuthLoading) {
            if (isAuthRoute) return null; // Allow staying on auth if signing in
            return isSplashRoute ? null : splashRoute;
          }

          // If unauthenticated, go to auth (unless already there)
          if (authState is Unauthenticated) {
            return isAuthRoute ? null : authRoute;
          }

          // If authenticated:
          if (authState is Authenticated) {
            // 1. If onboarding not seen, go to onboarding
            if (!onboardingSeen) {
              return isOnboardingRoute ? null : onboardingRoute;
            }

            // 2. If just finished onboarding or authenticated and on auth/splash/onboarding, go to home
            // Note: The user wants onboarding -> paywall -> dashboard.
            // We can handle the paywall transition in the onboarding page itself,
            // or here if we want it to be forced.
            if (isSplashRoute || isAuthRoute || isOnboardingRoute) {
              return homeRoute;
            }
          }

          return null;
        } catch (e) {
          debugPrint('Router redirect error: $e');
          return null;
        }
      },
      routes: [
        GoRoute(
          path: splashRoute,
          name: 'splash',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const SplashPage()),
        ),
        GoRoute(
          path: authRoute,
          name: 'auth',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const AuthPage()),
        ),
        GoRoute(
          path: onboardingRoute,
          name: 'onboarding',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const OnboardingPage()),
        ),
        GoRoute(
          path: paywallRoute,
          name: 'paywall',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const PaywallPage()),
        ),
        GoRoute(
          path: homeRoute,
          name: 'home',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const SecurityGate(child: AppShellPage()),
          ),
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Error: ${state.error}'))),
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
