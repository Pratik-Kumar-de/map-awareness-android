import 'package:flutter/material.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/routing.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/services/storage_service.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/widgets/roadwork_tile.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<SavedRoute> _savedRoutes = [];
  List<List<RoutingWidgetData>> _currentRoadworks = [];
  List<AutobahnClass> _currentAutobahnList = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _lastCalculatedStart;
  String? _lastCalculatedEnd;

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
    _startController.text = "53.084,8.798";
    _endController.text = "53.538,10.033";
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
    setState(() {
      _savedRoutes = routes;
    });
  }

  Future<void> _calculateRoute() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      context.showSnackBar('Please enter start and end coordinates');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final autobahnList = await routing(_startController.text, _endController.text);
      final roadworks = await getRoutingWidgetData(_startController.text, _endController.text);
      
      setState(() {
        _currentAutobahnList = autobahnList;
        _currentRoadworks = roadworks;
        _lastCalculatedStart = _startController.text;
        _lastCalculatedEnd = _endController.text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Error: $e');
    }
  }

  Future<void> _saveRoute() async {
    if (_currentAutobahnList.isEmpty) {
      context.showSnackBar('Calculate a route first', color: Colors.orange, floating: true);
      return;
    }

    setState(() => _isSaving = true);

    final name = _nameController.text.isNotEmpty 
        ? _nameController.text 
        : '$_lastCalculatedStart → $_lastCalculatedEnd';

    final route = SavedRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startCoordinate: _lastCalculatedStart!,
      endCoordinate: _lastCalculatedEnd!,
      autobahnSegments: autobahnClassToData(_currentAutobahnList),
      createdAt: DateTime.now(),
    );

    await StorageService.saveRoute(route);
    await _loadSavedRoutes();
    _nameController.clear();

    setState(() => _isSaving = false);

    if (!mounted) return;
    context.showSnackBar('Route "$name" saved', color: Colors.green, floating: true, duration: const Duration(seconds: 3));
  }

  Future<void> _loadRoute(SavedRoute route) async {
    setState(() => _isLoading = true);

    try {
      final roadworks = await getRoutingWidgetDataFromCache(route.autobahnSegments);
      
      setState(() {
        _startController.text = route.startCoordinate;
        _endController.text = route.endCoordinate;
        _currentRoadworks = roadworks;
        _lastCalculatedStart = route.startCoordinate;
        _lastCalculatedEnd = route.endCoordinate;
        _isLoading = false;
      });

      if (!mounted) return;
      context.showSnackBar('Loaded "${route.name}" (cached route, fresh roadworks)');
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Error: $e');
    }
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: Text('Are you sure you want to delete "${route.name}"?'),
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

    await StorageService.deleteRoute(route.id);
    await _loadSavedRoutes();

    if (!mounted) return;
    context.showSnackBar('Route "${route.name}" deleted', color: Colors.red, floating: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _startController,
              decoration: const InputDecoration(
                labelText: 'Start coordinates (lat,lng)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endController,
              decoration: const InputDecoration(
                labelText: 'End coordinates (lat,lng)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Route name (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _calculateRoute,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calculate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: _currentAutobahnList.isEmpty ? 'Calculate a route first' : '',
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isSaving || _currentAutobahnList.isEmpty ? null : _saveRoute,
                      icon: _isSaving 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Route'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ))
            else if (_currentRoadworks.isNotEmpty) ...[
              RoadworksSummary(roadworks: _currentRoadworks),
              const SizedBox(height: 16),
            ],
            if (_savedRoutes.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Saved Routes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedRoutes.length,
                itemBuilder: (context, index) {
                  final route = _savedRoutes[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(route.name),
                      subtitle: Text(
                        '${route.autobahnSegments.length} Autobahn segments',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _loadRoute(route),
                            tooltip: 'Load route',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteRoute(route),
                            tooltip: 'Delete route',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else if (!_isLoading && _savedRoutes.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No saved routes yet', style: TextStyle(color: Colors.grey)),
                      Text('Calculate a route and save it', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
