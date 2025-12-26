import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/storage_service.dart';
import 'package:map_awareness/services/location_service.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/APIs/nina_api.dart';
import 'package:map_awareness/APIs/dwd_api.dart';
import 'package:map_awareness/APIs/gemini_api.dart';
import 'package:map_awareness/APIs/autobahn_api.dart';
import 'package:map_awareness/widgets/roadwork_tile.dart';

import 'package:map_awareness/widgets/warning_card.dart';
import 'package:map_awareness/widgets/ai_summary_card.dart';
import 'package:map_awareness/pages/map_page.dart';
import 'package:map_awareness/widgets/empty_state.dart';

class RoutesPage extends StatefulWidget {
  final void Function(List<PointLatLng> polyline, List<LatLng> roadworkPoints, [List<List<RoutingWidgetData>>? roadworks])? onRouteCalculated;
  final void Function(int tabIndex)? onTabRequested;

  const RoutesPage({super.key, this.onRouteCalculated, this.onTabRequested});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  bool _gettingLocation = false;

  List<SavedRoute> _savedRoutes = [];
  List<List<RoutingWidgetData>> _currentRoadworks = [];
  List<AutobahnClass> _currentAutobahnList = [];
  List<PointLatLng> _currentPolylinePoints = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _lastCalculatedStart;
  String? _lastCalculatedEnd;
  String? _lastStartLocation; // City name for display
  String? _lastEndLocation;   // City name for display
  String? _editingRouteId; // Track route being edited
  List<WarningItem> _routeWarnings = []; // Weather warnings for route
  bool _isLoadingSummary = false;
  String? _aiSummary;




  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
    _startController.text = 'Bremen';
    _endController.text = 'Hamburg';
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await StorageService.loadRoutes();
    setState(() => _savedRoutes = routes);
  }

  Future<String> _resolveLocationName(String input) async {
    // Basic coordinate check
    final coordsRegex = RegExp(r'^(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)$');
    final match = coordsRegex.firstMatch(input.trim());
    
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(3)!);
      if (lat != null && lng != null) {
        final name = await reverseGeocode(lat, lng);
        if (name != null) return name;
      }
    }
    return input;
  }

  Future<String?> _geocodeAddress(String address) async {
    // Check if input is already "lat,lng"
    final coordsRegex = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    if (coordsRegex.hasMatch(address.trim())) {
      return address.trim().replaceAll(' ', '');
    }

    final results = await geocode(address, limit: 1);
    return results.isNotEmpty ? results.first.coordinates : null;
  }

  Future<void> _useMyLocationForRoute() async {
    setState(() => _gettingLocation = true);
    final coords = await getCurrentUserLocation();
    
    if (coords == null) {
      if (!mounted) return;
      setState(() => _gettingLocation = false);
      context.showSnackBar('Could not get location. Check permissions.', color: Colors.orange);
      return;
    }

    // We have coords "lat,lng". Geocoding API needs coords to get city name?
    // Or we can just use "My Location (lat,lng)" as text and handle it in _calculateRoute?
    // But _calculateRoute calls `_geocodeAddress` which expects a city/address string to geocode.
    // GraphHopper geocoding can reverse geocode?
    
    // Try to resolve city name for better UX
    final coordsParts = coords.split(',');
    final lat = double.parse(coordsParts[0]);
    final lng = double.parse(coordsParts[1]);
    
    _startController.text = coords; 
    
    // Async update to name if possible
    reverseGeocode(lat, lng).then((name) {
      if (name != null && mounted) {
        setState(() => _startController.text = name);
      }
    });

    setState(() => _gettingLocation = false);
  }

  Future<void> _calculateRoute() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      context.showSnackBar('Please enter start and end location');
      return;
    }

    setState(() {
      _isLoading = true;
      _aiSummary = null;
    });

    try {
      final startCoords = await _geocodeAddress(_startController.text);
      final endCoords = await _geocodeAddress(_endController.text);

      if (startCoords == null || endCoords == null) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        context.showSnackBar('Could not find location');
        return;
      }

      final routeResult = await routingWithPolyline(startCoords, endCoords);
      final roadworks = await getRoutingWidgetData(startCoords, endCoords);
      
      // Fetch warnings: DWD (national) + NINA (for start/end cities)
      final warnings = <WarningItem>[];
      try {
        // DWD national warnings
        final dwdWarnings = await getAllDWDWarnings();
        warnings.addAll(dwdWarnings.map(WarningItem.fromDWD));
        
        // NINA for start and end cities
        final startCity = _startController.text.split(',').first.trim();
        final endCity = _endController.text.split(',').first.trim();
        final startWarnings = await getNINAWarningsForCity(startCity);
        final endWarnings = await getNINAWarningsForCity(endCity);
        warnings.addAll(startWarnings.map(WarningItem.fromNINA));
        if (startCity.toLowerCase() != endCity.toLowerCase()) {
          warnings.addAll(endWarnings.map(WarningItem.fromNINA));
        }
        
        // Deduplicate by title
        final seen = <String>{};
        warnings.removeWhere((w) => !seen.add(w.title));
      } catch (_) {}
      
      final allRoadworks = [...roadworks[0], ...roadworks[1], ...roadworks[2]];
      
      // Resolve names for saving so we don't save coordinates
      final startLocation = await _resolveLocationName(_startController.text);
      final endLocation = await _resolveLocationName(_endController.text);

      setState(() {
        _currentAutobahnList = routeResult.autobahnList;
        _currentPolylinePoints = routeResult.polylinePoints;
        _currentRoadworks = roadworks;
        _routeWarnings = warnings..sort();
        _lastCalculatedStart = startCoords;
        _lastCalculatedEnd = endCoords;
        _lastStartLocation = startLocation;
        _lastEndLocation = endLocation;
        _isLoading = false;
        _isLoadingSummary = true;
      });

      final roadworkLatLngs = _extractRoadworkPoints(roadworks);
      widget.onRouteCalculated?.call(routeResult.polylinePoints, roadworkLatLngs, roadworks);
      
      // Generate AI summary in background
      _generateAiSummary(allRoadworks, warnings); 
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Error: $e');
    }
  }

  Future<void> _generateAiSummary(List<RoutingWidgetData> roadworks, List<WarningItem> warnings) async {
    try {
      final summary = await generateRouteSummary(
        roadworks,
        warnings,
        _lastStartLocation ?? '',
        _lastEndLocation ?? '',
      );
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _saveRoute() async {
    if (_currentAutobahnList.isEmpty) {
      context.showSnackBar('Calculate a route first', color: Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.isNotEmpty 
        ? _nameController.text 
        : '${_startController.text} → ${_endController.text}';

    final route = SavedRoute(
      id: _editingRouteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startCoordinate: _lastCalculatedStart!,
      endCoordinate: _lastCalculatedEnd!,
      startLocation: _lastStartLocation ?? _startController.text,
      endLocation: _lastEndLocation ?? _endController.text,
      autobahnSegments: autobahnClassToData(_currentAutobahnList),
      createdAt: DateTime.now(),
    );

    await StorageService.saveRoute(route);
    await _loadSavedRoutes();
    _nameController.clear();
    _editingRouteId = null;

    setState(() => _isSaving = false);
    if (!mounted) return;
    context.showSnackBar('Route saved', color: Colors.green);
  }

  Future<void> _editRoute(SavedRoute route) async {
    final startName = await _resolveLocationName(route.startLocation);
    final endName = await _resolveLocationName(route.endLocation);

    setState(() {
      _startController.text = startName;
      _endController.text = endName;
      _nameController.text = route.name;
      _editingRouteId = route.id;
    });
    if (!mounted) return;
    context.showSnackBar('Editing "${route.name}" - modify and recalculate');
  }

  Future<void> _loadRoute(SavedRoute route) async {
    _startController.text = route.startLocation;
    _endController.text = route.endLocation;
    _nameController.text = route.name;
    
    // Trigger fresh calculation to update map and get latest data
    await _calculateRoute();
    
    if (mounted) {
      context.showSnackBar('Loaded and refreshed "${route.name}"');
    }
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: Text('Delete "${route.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;
    await StorageService.deleteRoute(route.id);
    await _loadSavedRoutes();
    if (!mounted) return;
    context.showSnackBar('Route deleted', color: Colors.red);
  }

  List<LatLng> _extractRoadworkPoints(List<List<RoutingWidgetData>> roadworks) {
    return roadworks.expand((list) => list)
        .where((rw) => rw.latitude != null && rw.longitude != null)
        .map((rw) => LatLng(rw.latitude!, rw.longitude!))
        .toList();
  }

  void _viewOnMap() {
    if (_currentPolylinePoints.isEmpty) return;
    final routeLatLng = _currentPolylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final roadworkLatLngs = _extractRoadworkPoints(_currentRoadworks);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Route Map')),
          body: MapPage(
            routePoints: routeLatLng,
            startPoint: routeLatLng.first,
            endPoint: routeLatLng.last,
            roadworkPoints: roadworkLatLngs,
            roadworks: _currentRoadworks,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.directions_outlined), text: 'Plan'),
              Tab(icon: Icon(Icons.bookmarks_outlined), text: 'Saved'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCalculatorTab(),
                _buildSavedRoutesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editingRouteId != null)
            _buildEditingBanner(colorScheme),
          
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   TextField(
                    controller: _startController,
                    decoration: InputDecoration(
                      labelText: 'Start Location', 
                      hintText: 'City or address', 
                      prefixIcon: const Icon(Icons.trip_origin),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        onPressed: _gettingLocation ? null : _useMyLocationForRoute,
                        icon: _gettingLocation 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                        tooltip: 'Use my location',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    heightFactor: 0.5,
                    child: FloatingActionButton.small(
                      elevation: 0,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      foregroundColor: colorScheme.primary,
                      shape: const CircleBorder(),
                      onPressed: () {
                        final temp = _startController.text;
                        _startController.text = _endController.text;
                        _endController.text = temp;
                      },
                      child: const Icon(Icons.swap_vert),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _endController,
                    decoration: InputDecoration(
                      labelText: 'Destination', 
                      hintText: 'City or address', 
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Route Name (Optional)', 
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _calculateRoute,
                  icon: const Icon(Icons.directions),
                  label: const Text('Calculate Route'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || _isSaving || _currentAutobahnList.isEmpty ? null : _saveRoute,
                  icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bookmark_border),
                  label: Text(_isSaving ? 'Saving...' : (_editingRouteId != null ? 'Update' : 'Save')),
                  style: OutlinedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
          else ...[
            if (_currentRoadworks.isNotEmpty) ...[ 
              RoadworksSummary(roadworks: _currentRoadworks),
              const SizedBox(height: 16),
            ],
            // Route warnings section
            if (_routeWarnings.isNotEmpty) 
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  key: const PageStorageKey<String>('route_warnings'),
                  initiallyExpanded: false,
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text(
                    '${_routeWarnings.length} Warnings on Route',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.all(8),
                  subtitle: const Text('Civil protection & weather alerts'),
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  children: _routeWarnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: WarningCard(warning: w),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 16),
            // AI summary section
            if (_currentRoadworks.isNotEmpty || _routeWarnings.isNotEmpty) 
              AiSummaryCard(
                summary: _aiSummary,
                isLoading: _isLoadingSummary,
                title: _lastStartLocation != null && _lastEndLocation != null 
                    ? 'Route: $_lastStartLocation → $_lastEndLocation' 
                    : 'Route Summary',
                onRefresh: () {
                  final allRoadworks = [..._currentRoadworks[0], ..._currentRoadworks[1], ..._currentRoadworks[2]];
                  setState(() => _isLoadingSummary = true);
                  _generateAiSummary(allRoadworks, _routeWarnings);
                },
              ),
            const SizedBox(height: 16),
            if (_currentPolylinePoints.isNotEmpty) 
              SizedBox(
                width: double.infinity, 
                child: FilledButton.tonalIcon(
                  onPressed: _viewOnMap, 
                  icon: const Icon(Icons.map_outlined), 
                  label: const Text('View on Map'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildEditingBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 20, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editing route...',
              style: TextStyle(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() { _editingRouteId = null; _nameController.clear(); }),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRoutesTab() {
    if (_savedRoutes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_border,
        title: 'No saved routes yet',
        subtitle: 'Go to "Plan Route" to create one',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedRoutes.length,
      itemBuilder: (context, index) {
        final route = _savedRoutes[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: const Icon(Icons.route),
            title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${route.autobahnSegments.length} Autobahn segments'),
            onTap: () {
             // Switch to plan tab and load
             _loadRoute(route);
             DefaultTabController.of(context).animateTo(0);
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () {
                   _editRoute(route);
                   DefaultTabController.of(context).animateTo(0);
                }, tooltip: 'Edit'),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteRoute(route), tooltip: 'Delete'),
              ],
            ),
          ),
        );
      },
    );
  }
}
