import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:map_awareness/screens/routes/routes_screen.dart';
import 'package:map_awareness/screens/warnings/warnings_screen.dart';
import 'package:map_awareness/screens/map/map_screen.dart';
import 'package:map_awareness/screens/settings/settings_screen.dart';
import 'package:map_awareness/widgets/layout/app_shell.dart';

/// App routes using go_router
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
            pageBuilder: (context, state) => const NoTransitionPage(child: RoutesScreen()),
          ),
          GoRoute(
            path: '/warnings',
            pageBuilder: (context, state) => const NoTransitionPage(child: WarningsScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => const NoTransitionPage(child: MapScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    ],
  );

  static void goToRoutes() => router.go('/routes');
  static void goToWarnings() => router.go('/warnings');
  static void goToMap() => router.go('/map');
  static void goToSettings() => router.push('/settings');

  static int get currentIndex {
    final location = router.routerDelegate.currentConfiguration.fullPath;
    if (location.startsWith('/warnings')) return 1;
    if (location.startsWith('/map')) return 2;
    return 0;
  }
}
