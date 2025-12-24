import 'package:flutter/material.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/services/storage_service.dart';

class LocationRadiusPage extends StatefulWidget {
  const LocationRadiusPage({super.key});

  @override
  State<LocationRadiusPage> createState() => _LocationRadiusPageState();
}

class _LocationRadiusPageState extends State<LocationRadiusPage> {
  final TextEditingController _searchController = TextEditingController();
  double _radiusKm = 20;
  List<SavedLocation> _savedLocations = [];
  bool _isSaving = false;

  final List<_WarningItem> _warnings = const [
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

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await StorageService.loadLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  void _useMyLocation() {
    context.showSnackBar('GPS location feature coming soon', floating: true);
  }

  void _search() {
    context.showSnackBar('Searching for "${_searchController.text}" within ${_radiusKm.toInt()} km');
  }

  Future<void> _saveLocation() async {
    if (_searchController.text.isEmpty) {
      context.showSnackBar('Enter a location first', color: Colors.orange, floating: true);
      return;
    }

    setState(() => _isSaving = true);

    final location = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _searchController.text,
      locationText: _searchController.text,
      radiusKm: _radiusKm,
      createdAt: DateTime.now(),
    );

    await StorageService.saveLocation(location);
    await _loadSavedLocations();

    setState(() => _isSaving = false);

    if (!mounted) return;
    context.showSnackBar('Location "${location.name}" saved', color: Colors.green, floating: true, duration: const Duration(seconds: 3));
  }

  void _loadLocation(SavedLocation location) {
    setState(() {
      _searchController.text = location.locationText;
      _radiusKm = location.radiusKm;
    });
    context.showSnackBar('Loaded "${location.name}"');
  }

  Future<void> _deleteLocation(SavedLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location?'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await StorageService.deleteLocation(location.id);
    await _loadSavedLocations();

    if (!mounted) return;
    context.showSnackBar('Location "${location.name}" deleted', color: Colors.red, floating: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check warnings for a location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Enter a location (city, address …)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useMyLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my location'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: _searchController.text.isEmpty ? 'Enter a location first' : '',
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveLocation,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Location'),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          if (_savedLocations.isNotEmpty) ...[
            const Text(
              'Saved Locations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _savedLocations.length,
                itemBuilder: (context, index) {
                  final loc = _savedLocations[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      avatar: const Icon(Icons.location_on, size: 18),
                      label: Text('${loc.name} (${loc.radiusKm.toInt()}km)'),
                      onPressed: () => _loadLocation(loc),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _deleteLocation(loc),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Warnings in this area:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _warnings.length,
              itemBuilder: (context, index) {
                final warning = _warnings[index];
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
