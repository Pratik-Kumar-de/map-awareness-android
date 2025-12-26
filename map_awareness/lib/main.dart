import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/screens/routes/routes_screen.dart';
import 'package:map_awareness/screens/warnings/warnings_screen.dart';
import 'package:map_awareness/screens/map/map_screen.dart';
import 'package:map_awareness/screens/settings/settings_screen.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/app_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    return MaterialApp(
      title: 'Map Awareness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const HomeScreen(),
      builder: (context, child) {
        if (isWindows) {
          return Semantics(container: true, excludeSemantics: true, child: child);
        }
        return child!;
      },
    );
  }
}

/// Main app shell with premium navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  List<PointLatLng> _routePolyline = [];
  List<LatLng> _roadworkPoints = [];
  List<List<RoutingWidgetData>>? _roadworks;
  
  LatLng? _warningCenter;
  double? _warningRadius;
  List<WarningItem>? _warningItems;

  late final List<_PageConfig> _pages;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      _PageConfig(
        title: 'Routes',
        subtitle: 'Plan your journey',
        icon: Icons.alt_route_rounded,
      ),
      _PageConfig(
        title: 'Warnings',
        subtitle: 'Stay informed',
        icon: Icons.warning_amber_rounded,
      ),
      _PageConfig(
        title: 'Map',
        subtitle: 'Explore your route',
        icon: Icons.map_rounded,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onRouteCalculated(List<PointLatLng> polyline, List<LatLng> roadworkPoints, [List<List<RoutingWidgetData>>? roadworks]) {
    setState(() {
      _routePolyline = polyline;
      _roadworkPoints = roadworkPoints;
      _roadworks = roadworks;
      _warningCenter = null;
      _warningRadius = null;
      _warningItems = null;
    });
  }

  void _onViewWarningsMap(LatLng center, double radiusKm, List<WarningItem> warnings) {
    setState(() {
      _warningCenter = center;
      _warningRadius = radiusKm;
      _warningItems = warnings;
      _routePolyline = [];
      _roadworkPoints = [];
      _roadworks = null;
    });
    _navigateToPage(2);
  }

  void _navigateToPage(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppTheme.durationMedium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapPoints = _routePolyline.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final currentPage = _pages[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Premium header
            _buildHeader(context, currentPage),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  RoutesScreen(
                    onRouteCalculated: _onRouteCalculated,
                    onTabRequested: _navigateToPage,
                  ),
                  WarningsScreen(onViewMap: _onViewWarningsMap),
                  MapScreen(
                    routePoints: mapPoints.isNotEmpty ? mapPoints : null,
                    startPoint: _warningCenter ?? (mapPoints.isNotEmpty ? mapPoints.first : null),
                    endPoint: mapPoints.isNotEmpty ? mapPoints.last : null,
                    roadworkPoints: _roadworkPoints.isNotEmpty ? _roadworkPoints : null,
                    roadworks: _roadworks,
                    radiusKm: _warningRadius,
                    warnings: _warningItems,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _navigateToPage,
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
          // Animated icon container
          AnimatedContainer(
            duration: AppTheme.durationMedium,
            curve: Curves.easeOutCubic,
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
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: AppTheme.durationFast,
                  child: Text(
                    page.title,
                    key: ValueKey(page.title),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: AppTheme.durationFast,
                  child: Text(
                    page.subtitle,
                    key: ValueKey(page.subtitle),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context1, a1, a2) => const SettingsScreen(),
                    transitionsBuilder: (context2, animation, a3, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: AppTheme.durationMedium,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageConfig {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PageConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
