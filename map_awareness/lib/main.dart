import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/pages/location_radius_page.dart';
import 'package:map_awareness/pages/routes_page.dart';
import 'package:map_awareness/pages/map_page.dart';
import 'package:map_awareness/pages/settings_page.dart';
import 'package:map_awareness/models/routing_data.dart';

import 'package:map_awareness/utils/app_theme.dart';

void main() {
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
      home: const MainScaffold(),
      builder: (context, child) {
        if (isWindows) {
          return Semantics(
            container: true,
            excludeSemantics: true,
            child: child,
          );
        }
        return child!;
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  List<PointLatLng> _routePolyline = [];
  List<LatLng> _roadworkPoints = [];
  List<List<RoutingWidgetData>>? _roadworks;

  final List<String> _titles = const ['Routes', 'Warnings', 'Map'];

  void _onRouteCalculated(List<PointLatLng> polyline, List<LatLng> roadworkPoints, [List<List<RoutingWidgetData>>? roadworks]) {
    setState(() {
      _routePolyline = polyline;
      _roadworkPoints = roadworkPoints;
      _roadworks = roadworks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapPoints = _routePolyline.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Settings button in app bar
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RoutesPage(
            onRouteCalculated: _onRouteCalculated,
            onTabRequested: (index) => setState(() => _currentIndex = index),
          ),
          const LocationRadiusPage(),
          MapPage(
            routePoints: mapPoints.isNotEmpty ? mapPoints : null,
            startPoint: mapPoints.isNotEmpty ? mapPoints.first : null,
            endPoint: mapPoints.isNotEmpty ? mapPoints.last : null,
            roadworkPoints: _roadworkPoints.isNotEmpty ? _roadworkPoints : null,
            roadworks: _roadworks,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alt_route), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Warnings'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
