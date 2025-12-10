import 'package:flutter/material.dart';
import 'package:map_awareness/APIs/autobahn_api.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/pages/location_radius_page.dart'; // <- my page

void main() {
  runApp(const MyApp());
}

/// Root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Awareness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // I use my own scaffold with bottom navigation
      home: const MainScaffold(),
    );
  }
}

/// Main scaffold with 3 tabs:
/// 1) Routes  (Marvin's Autobahn + routing test)
/// 2) Location & Radius (my feature)
/// 3) Map     (placeholder for later)
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Pages for the bottom navigation
  final List<Widget> _pages = const [
    RoutesPage(),
    LocationRadiusPage(),  // <--- my page
    MapPage(),
  ];

  final List<String> _titles = const [
    'Routes',
    'Location & Radius',
    'Map',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

/// ----------------------
/// 1) ROUTES PAGE (old MyHomePage)
/// This still calls `testAutobahnAPI` and `routing` when user presses + button.
/// ----------------------
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  void _callApis() {
    setState(() {
      // button calls test methods from the Autobahn + map API files
      testAutobahnAPI("A1");

      // Example coordinates: Bremen -> Hamburg
      routing("53.084,8.798", "53.538,10.033");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Routes page\n\n'
              'Here we can later show the route\n'
              'and incidents from Autobahn API.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _callApis,
        tooltip: 'Test APIs',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ----------------------
/// 2) LOCATION & RADIUS PAGE
/// This comes from my own file: pages/location_radius_page.dart
/// (nothing to do here in main.dart, just navigation)
/// ----------------------
/// class LocationRadiusPage is imported from the other file.

/// ----------------------
/// 3) SIMPLE MAP PAGE (placeholder)
/// ----------------------
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Map page\n\nHere we can show the real map later.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
