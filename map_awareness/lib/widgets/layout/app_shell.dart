import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/screens/routes/routes_screen.dart';
import 'package:map_awareness/screens/warnings/warnings_screen.dart';
import 'package:map_awareness/screens/map/map_screen.dart';


/// Root layout widget interacting with AppRouter to manage bottom navigation and page switching.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

/// State for AppShell managing PageController and navigation synchronization.
class _AppShellState extends ConsumerState<AppShell> {
  late PageController _pageController;
  int _currentPage = 0;

  static const _pages = [
    _PageConfig('Routes', 'Plan your journey', Icons.alt_route_rounded),
    _PageConfig('Warnings', 'Stay informed', Icons.warning_amber_rounded),
    _PageConfig('Map', 'Explore your route', Icons.map_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = AppRouter.currentIndex;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = AppRouter.currentIndex;
    if (_currentPage != newIndex) {
      setState(() => _currentPage = newIndex);
      _pageController.jumpToPage(newIndex);
    }
  }

  /// Handles page view updates and syncs with router.
  void _onPageChanged(int index) {
    if (_currentPage != index) {
      setState(() => _currentPage = index);
      Haptics.select();
      switch (index) {
        case 0: AppRouter.goToRoutes();
        case 1: AppRouter.goToWarnings();
        case 2: AppRouter.goToMap();
      }
    }
  }

  /// Handles bottom navigation taps, triggering smooth scroll animation.
  void _onNavTap(int index) {
    Haptics.select();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, theme, page),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: const [
                  RoutesScreen(),
                  WarningsScreen(),
                  MapScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentPage,
        onTap: _onNavTap,
      ),
    );
  }

  /// Builds the dynamic header containing page title, icon, and settings button.
  Widget _buildHeader(BuildContext context, ThemeData theme, _PageConfig page) {
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(page.icon, color: theme.colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  page.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

/// Internal configuration for a main navigation page.
class _PageConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  const _PageConfig(this.title, this.subtitle, this.icon);
}

/// Floating-style settings button for the app header.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton.filledTonal(
      onPressed: () {
        Haptics.select();
        AppRouter.goToSettings();
      },
      icon: const Icon(Icons.settings_outlined, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
      ),
    );
  }
}

/// Custom bottom navigation bar synchronized with the PageView.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        Haptics.select();
        onTap(i);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.alt_route_rounded),
          label: 'Routes',
          tooltip: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.warning_amber_rounded),
          label: 'Warnings',
          tooltip: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_rounded),
          label: 'Map',
          tooltip: '',
        ),
      ],
    );
  }
}
