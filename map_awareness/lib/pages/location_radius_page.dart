import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/widgets/warning_card.dart';
import 'package:map_awareness/widgets/ai_summary_card.dart';
import 'package:map_awareness/services/storage_service.dart';
import 'package:map_awareness/services/location_service.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/APIs/dwd_api.dart';
import 'package:map_awareness/APIs/nina_api.dart';
import 'package:map_awareness/APIs/gemini_api.dart';
import 'package:map_awareness/APIs/open_meteo_api.dart';
import 'package:map_awareness/pages/map_page.dart';
import 'package:map_awareness/widgets/empty_state.dart';

class LocationRadiusPage extends StatefulWidget {
  const LocationRadiusPage({super.key});

  @override
  State<LocationRadiusPage> createState() => _LocationRadiusPageState();
}

class _LocationRadiusPageState extends State<LocationRadiusPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<WarningSeverity> _selectedSeverities = {};
  
  double _radiusKm = 20;
  List<SavedLocation> _savedLocations = [];
  List<WarningItem> _warnings = [];
  List<WarningItem> _infoItems = [];
  Map<String, dynamic>? _rawAirQuality;
  Map<String, dynamic>? _rawFloodData;
  bool _isSaving = false;
  bool _isLoading = false;
  bool _showOnlyActive = false;
  double? _currentLat;
  double? _currentLng;
  String? _aiSummary;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _selectedSeverities.addAll(WarningSeverity.values);
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await StorageService.loadLocations();
    setState(() => _savedLocations = locations);
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLoading = true);

    final coords = await getCurrentUserLocation();
    if (coords == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Could not get location. Check permissions.', color: Colors.orange);
      return;
    }

    final parts = coords.split(',');
    _currentLat = double.tryParse(parts[0]);
    _currentLng = double.tryParse(parts[1]);
    _searchController.text = 'My Location ($coords)';

    await _fetchWarnings();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      context.showSnackBar('Enter a location first', color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final results = await geocode(_searchController.text, limit: 1);
    if (results.isEmpty) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Location not found', color: Colors.orange);
      return;
    }

    _currentLat = results.first.lat;
    _currentLng = results.first.lng;
    _searchController.text = results.first.displayName;

    await _fetchWarnings();
  }

  Future<void> _fetchWarnings() async {
    final allWarnings = <WarningItem>[];
    final allInfoItems = <WarningItem>[];

    try {
      final dwdWarnings = await getAllDWDWarnings();
      allWarnings.addAll(dwdWarnings.map(WarningItem.fromDWD));
    } catch (_) {}

    try {
      final ninaWarnings = await getNINAWarningsForCity(
        _searchController.text.split(',').first.trim(),
      );
      allWarnings.addAll(ninaWarnings.map(WarningItem.fromNINA));
    } catch (_) {}

    // OpenMeteo Air Quality & Flood (only if we have coords)
    Map<String, dynamic>? rawAq;
    Map<String, dynamic>? rawFlood;
    if (_currentLat != null && _currentLng != null) {
       try {
         final aqData = await OpenMeteoApi.getAirQuality(_currentLat!, _currentLng!);
         if (aqData != null) {
           rawAq = aqData;
           final item = WarningItem.fromOpenMeteoAirQuality(aqData);
           if (item != null) allInfoItems.add(item);
         }
       } catch (_) {}

       try {
         final floodData = await OpenMeteoApi.getFloodData(_currentLat!, _currentLng!);
         if (floodData != null) {
           rawFlood = floodData;
           final item = WarningItem.fromOpenMeteoFlood(floodData);
           if (item != null) allInfoItems.add(item);
         }
       } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _warnings = allWarnings;
        _infoItems = allInfoItems;
        _rawAirQuality = rawAq;
        _rawFloodData = rawFlood;
        _isLoading = false;
      });
      _generateLocationSummary(allWarnings, allInfoItems);
    }
  }

  /// Filters warnings to only those within the radius of user location
  List<WarningItem> _filterByRadius(List<WarningItem> warnings) {
    // If no user location, return warnings with no coords (can't filter)
    if (_currentLat == null || _currentLng == null) return warnings;
    
    return warnings.where((w) {
      // Keep warnings without coords (benefit of doubt)
      if (w.latitude == null || w.longitude == null) return true;
      // Calculate distance and check if within radius
      final dist = distanceInKm(_currentLat!, _currentLng!, w.latitude!, w.longitude!);
      return dist <= _radiusKm;
    }).toList();
  }

  Future<void> _generateLocationSummary(List<WarningItem> warnings, List<WarningItem> infoItems) async {
    try {
      final summary = await generateLocationSummary(
        _searchController.text.split(',').first.trim(),
        warnings,
        radiusKm: _radiusKm,
        airQuality: _rawAirQuality,
        floodData: _rawFloodData,
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

  /// Opens map with radius circle at current location
  void _viewOnMap() {
    if (_currentLat == null || _currentLng == null) {
      context.showSnackBar('Search a location first', color: Colors.orange);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('${_searchController.text.split(',').first} - ${_radiusKm.toInt()} km')),
          body: MapPage(
            startPoint: LatLng(_currentLat!, _currentLng!),
            radiusKm: _radiusKm,
            warnings: _warnings,
          ),
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (_searchController.text.isEmpty) {
      context.showSnackBar('Enter a location first', color: Colors.orange, floating: true);
      return;
    }

    setState(() => _isSaving = true);

    final location = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _searchController.text.split(',').first,
      locationText: _searchController.text,
      radiusKm: _radiusKm,
      createdAt: DateTime.now(),
      latitude: _currentLat,
      longitude: _currentLng,
    );

    final success = await StorageService.saveLocation(location);
    await _loadSavedLocations();

    setState(() => _isSaving = false);
    if (!mounted) return;
    if (success) {
      context.showSnackBar('Location saved', color: Colors.green, floating: true);
    } else {
      context.showSnackBar('Location already saved', color: Colors.orange, floating: true);
    }
  }

  Future<void> _deleteLocation(SavedLocation location) async {
    await StorageService.deleteLocation(location.id);
    await _loadSavedLocations();
    if (!mounted) return;
    context.showSnackBar('${location.name} removed', floating: true);
  }

  void _loadLocation(SavedLocation location) {
    setState(() {
      _searchController.text = location.locationText;
      _radiusKm = location.radiusKm;
      _currentLat = location.latitude;
      _currentLng = location.longitude;
    });
    _fetchWarnings();
  }


  List<WarningItem> get _filteredWarnings {
    final basics = _warnings.where((w) {
      if (_showOnlyActive && !w.isActive) return false;
      if (!_selectedSeverities.contains(w.severity)) return false;
      return true;
    }).toList();
    return _filterByRadius(basics);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredWarnings;

    return RefreshIndicator(
      onRefresh: _fetchWarnings,
      child: CustomScrollView(
        key: const PageStorageKey<String>('unified_warnings_page'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchCard(theme),
                  
                  if (_savedLocations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSavedLocations(theme),
                  ],
      
                  const SizedBox(height: 16),
                  
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else ...[
                    // AI Summary
                    AiSummaryCard(
                      summary: _aiSummary,
                      isLoading: _isLoadingSummary,
                      title: _searchController.text.isNotEmpty 
                          ? 'Area: ${_searchController.text.split(',').first}' 
                          : 'Location Summary',
                      onRefresh: () {
                        setState(() => _isLoadingSummary = true);
                        _generateLocationSummary(_warnings, _infoItems);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistics
                    _buildStatisticsCard(theme),
                    
                    const SizedBox(height: 16),

                    // Filters & Map
                    Row(
                      children: [
                        Expanded(
                          child: WarningFilters(
                            selectedCategories: WarningCategory.values.toSet(),
                            selectedSeverities: _selectedSeverities,
                            showOnlyActive: _showOnlyActive,
                            onCategoryToggle: (_) {},
                            onSeverityToggle: (s) => setState(() {
                              if (_selectedSeverities.contains(s)) {
                                _selectedSeverities.remove(s);
                              } else {
                                _selectedSeverities.add(s);
                              }
                            }),
                            onActiveToggle: (v) => setState(() => _showOnlyActive = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _viewOnMap,
                          icon: const Icon(Icons.map_rounded),
                          tooltip: 'View on Map',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    if (_infoItems.isNotEmpty) ...[
                      _buildInfoSection(theme),
                      const SizedBox(height: 16),
                    ],

                    if (_warnings.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.search_rounded,
                        title: 'Search a location',
                        subtitle: 'Warnings from DWD and NINA will appear here.\nTry searching for "Berlin" or use your location.',
                      )
                    else if (filtered.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No warnings match',
                        subtitle: 'Try adjusting your filters.',
                      )
                    else
                      ...filtered.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: WarningCard(warning: w),
                      )),
                    
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(ThemeData theme) {
    if (_warnings.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Warnings', '${_warnings.length}', theme),
            _buildStatRow('Active Warnings', '${_warnings.where((w) => w.isActive).length}', theme),
            _buildStatRow('Highest Severity', _warnings.isEmpty ? "None" : _warnings.first.severity.label, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.my_location_rounded),
                        tooltip: 'Use My Location',
                        onPressed: _useMyLocation,
                      ),
                    IconButton(
                      icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.bookmark_border_rounded),
                      tooltip: 'Save Location',
                      onPressed: _isSaving ? null : _saveLocation,
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
             _buildRadiusControl(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusControl(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Search Radius', style: theme.textTheme.labelLarge),
            Badge(
              label: Text('${_radiusKm.toInt()} km'),
              backgroundColor: theme.colorScheme.primaryContainer,
              textColor: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
        Slider(
          min: 1,
          max: 100,
          divisions: 99,
          value: _radiusKm,
          onChanged: (value) => setState(() => _radiusKm = value),
        ),
      ],
    );
  }

  Widget _buildSavedLocations(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _savedLocations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final loc = _savedLocations[index];
          return GestureDetector(
            onLongPress: () => _showDeleteDialog(loc),
            child: ActionChip(
              avatar: const Icon(Icons.place_outlined, size: 16),
              label: Text(loc.name),
              onPressed: () => _loadLocation(loc),
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(SavedLocation location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${location.name}?'),
        content: const Text('This saved location will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLocation(location);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _infoItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _infoItems[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primaryContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.category == WarningCategory.flood ? Icons.water : Icons.eco,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
