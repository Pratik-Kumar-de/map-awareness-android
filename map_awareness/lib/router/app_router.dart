import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:map_awareness/screens/routes/routes_screen.dart';
import 'package:map_awareness/screens/warnings/warnings_screen.dart';
import 'package:map_awareness/screens/map/map_screen.dart';
import 'package:map_awareness/screens/settings/settings_screen.dart';
import 'package:map_awareness/widgets/layout/app_shell.dart';
import 'package:map_awareness/utils/app_animations.dart';

/// Configuration for application routing using GoRouter.
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/routes',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/routes',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const RoutesScreen(),
              transitionsBuilder: (context, animation, _, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: AppAnimations.fast,
            ),
          ),
          GoRoute(
            path: '/warnings',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const WarningsScreen(),
              transitionsBuilder: (context, animation, _, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: AppAnimations.fast,
            ),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const MapScreen(),
              transitionsBuilder: (context, animation, _, child) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              transitionDuration: AppAnimations.fast,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AppAnimations.emphasizedCurve,
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-0.3, 0),
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: AppAnimations.emphasizedCurve,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: AppAnimations.normal,
        ),
      ),
    ],
  );

  // Navigation helpers.
  static void goToRoutes() => router.go('/routes');
  static void goToWarnings() => router.go('/warnings');
  static void goToMap() => router.go('/map');
  static void goToSettings() => router.push('/settings');

  /// Determines the current bottom navigation index based on the route path.
  static int get currentIndex {
    final location = router.routerDelegate.currentConfiguration.fullPath;
    if (location.startsWith('/warnings')) return 1;
    if (location.startsWith('/map')) return 2;
    return 0;
  }
}
