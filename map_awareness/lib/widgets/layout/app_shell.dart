import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Main app shell with header and bottom navigation
class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _pages = [
    _PageConfig('Routes', 'Plan your journey', Icons.alt_route_rounded),
    _PageConfig('Warnings', 'Stay informed', Icons.warning_amber_rounded),
    _PageConfig('Map', 'Explore your route', Icons.map_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = AppRouter.currentIndex;
    final page = _pages[currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, page),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          switch (i) {
            case 0: AppRouter.goToRoutes();
            case 1: AppRouter.goToWarnings();
            case 2: AppRouter.goToMap();
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _PageConfig page) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.06),
            AppTheme.accent.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  page.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          _SettingsButton(),
        ],
      ),
    );
  }
}

class _PageConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  const _PageConfig(this.title, this.subtitle, this.icon);
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () {
        HapticFeedback.selectionClick();
        AppRouter.goToSettings();
      },
      icon: const Icon(Icons.settings_outlined, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textSecondary,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        HapticFeedback.selectionClick();
        onTap(i);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.alt_route_rounded),
          label: 'Routes',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_rounded),
          label: 'Warnings',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_rounded),
          label: 'Map',
        ),
      ],
    );
  }
}
