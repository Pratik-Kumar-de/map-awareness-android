import 'package:flutter/material.dart';

/// This page belongs to *my part of the project*
/// My task: “Location & Radius” – show warnings for an entered place.
class LocationRadiusPage extends StatefulWidget {
  const LocationRadiusPage({super.key});

  @override
  State<LocationRadiusPage> createState() => _LocationRadiusPageState();
}

class _LocationRadiusPageState extends State<LocationRadiusPage> {
  // Controller for the TextField (to read what the user typed)
  final TextEditingController _searchController = TextEditingController();

  // The radius the user can choose – starts at 20 km
  double _radiusKm = 20;

  // For now I use demo warnings.
  // Later we will replace these with real API data (DWD + NINA).
  final List<_WarningItem> _demoWarnings = const [
    _WarningItem(
      title: 'Severe Weather Warning',
      source: 'DWD',
      description: 'Strong wind and heavy rain expected in this area.',
    ),
    _WarningItem(
      title: 'Civil Protection Alert',
      source: 'NINA',
      description: 'Road blocked due to an accident. Expect delays.',
    ),
    _WarningItem(
      title: 'Heat Warning',
      source: 'DWD',
      description: 'High temperatures today. Stay hydrated!',
    ),
  ];

  /// This button simulates using the current GPS location.
  /// (Later we will replace it with geolocator or a real GPS plugin.)
  void _useMyLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using current location (demo only).'),
      ),
    );
  }

  /// When the user taps “Search”
  /// → I show a small popup message (later real API call).
  void _search() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Searching for "${_searchController.text}" '
              'within ${_radiusKm.toInt()} km (demo only).',
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),

      // I use a Column to stack all elements from top → bottom
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Check warnings for a location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // ==========================
          //   SEARCH TEXT FIELD
          // ==========================
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Enter a location (city, address …)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),

              // Clear button on the right side
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ==========================
          //   BUTTONS ROW
          // ==========================
          Row(
            children: [
              // Left button (outlined)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my location'),
                ),
              ),

              const SizedBox(width: 8),

              // Right button (filled)
              Expanded(
                child: FilledButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==========================
          //    RADIUS SLIDER
          // ==========================
          Text(
            'Radius: ${_radiusKm.toInt()} km',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          Slider(
            min: 1,
            max: 100,
            divisions: 99,
            value: _radiusKm,
            label: '${_radiusKm.toInt()} km',
            onChanged: (value) {
              setState(() {
                _radiusKm = value;
              });
            },
          ),

          const SizedBox(height: 10),

          // Section title for warnings
          const Text(
            'Warnings in this area (demo):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // ==========================
          //   LIST OF WARNINGS
          // ==========================
          Expanded(
            child: ListView.builder(
              itemCount: _demoWarnings.length,
              itemBuilder: (context, index) {
                final warning = _demoWarnings[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text(warning.title),
                    subtitle: Text(warning.description),
                    trailing: Text(
                      warning.source,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// This is just a simple model class I made for the warning items.
/// It helps to keep the data organized.
class _WarningItem {
  final String title;
  final String source;
  final String description;

  const _WarningItem({
    required this.title,
    required this.source,
    required this.description,
  });
}
