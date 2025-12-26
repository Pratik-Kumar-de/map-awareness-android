import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/components/loading/shimmer_loading.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/storage_service.dart';
import 'package:map_awareness/services/location_service.dart';
import 'package:map_awareness/APIs/map_api.dart';
import 'package:map_awareness/APIs/dwd_api.dart';
import 'package:map_awareness/APIs/nina_api.dart';
import 'package:map_awareness/APIs/gemini_api.dart';
import 'package:map_awareness/APIs/open_meteo_api.dart';
import 'package:map_awareness/widgets/warning_card.dart';
import 'package:map_awareness/widgets/ai_summary_card.dart';
import 'package:map_awareness/widgets/empty_state.dart';
import 'package:map_awareness/widgets/premium_inputs.dart';
import 'package:map_awareness/widgets/app_navigation.dart';
import 'package:map_awareness/widgets/app_header.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/premium_card.dart';

/// Warnings screen with premium UI
class WarningsScreen extends StatefulWidget {
  final void Function(LatLng center, double radiusKm, List<WarningItem> warnings)? onViewMap;

  const WarningsScreen({super.key, this.onViewMap});

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  final _searchController = TextEditingController();
  final Set<WarningSeverity> _selectedSeverities = {...WarningSeverity.values};

  List<SavedLocation> _savedLocations = [];
  List<WarningItem> _warnings = [];
  List<WarningItem> _infoItems = [];
  Map<String, dynamic>? _rawAirQuality, _rawFloodData;
  String? _aiSummary;
  double? _lat, _lng;
  double _radiusKm = 20;
  bool _isLoading = false, _isSaving = false, _isLoadingSummary = false, _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    final locs = await StorageService.loadLocations();
    setState(() => _savedLocations = locs);
  }

  Future<void> _useMyLocation() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    final coords = await getCurrentUserLocation();
    if (coords == null) {
      if (mounted) context.showSnackBar('Location unavailable', color: AppTheme.warning);
      setState(() => _isLoading = false);
      return;
    }
    final parts = coords.split(',');
    _lat = double.tryParse(parts[0]);
    _lng = double.tryParse(parts[1]);
    _searchController.text = 'My Location ($coords)';
    await _fetchWarnings();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      context.showSnackBar('Enter a location first', color: AppTheme.warning);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    final results = await geocode(_searchController.text, limit: 1);
    if (results.isEmpty) {
      if (mounted) context.showSnackBar('Location not found', color: AppTheme.error);
      setState(() => _isLoading = false);
      return;
    }
    _lat = results.first.lat;
    _lng = results.first.lng;
    _searchController.text = results.first.displayName;
    await _fetchWarnings();
  }

  Future<void> _fetchWarnings() async {
    final allWarnings = <WarningItem>[];
    final allInfoItems = <WarningItem>[];

    try {
      allWarnings.addAll((await getAllDWDWarnings()).map(WarningItem.fromDWD));
    } catch (_) {}

    try {
      final city = _searchController.text.split(',').first.trim();
      allWarnings.addAll((await getNINAWarningsForCity(city)).map(WarningItem.fromNINA));
    } catch (_) {}

    Map<String, dynamic>? rawAq, rawFlood;
    if (_lat != null && _lng != null) {
      try {
        final aq = await OpenMeteoApi.getAirQuality(_lat!, _lng!);
        if (aq != null) {
          rawAq = aq;
          final item = WarningItem.fromOpenMeteoAirQuality(aq);
          if (item != null) allInfoItems.add(item);
        }
      } catch (_) {}
      try {
        final flood = await OpenMeteoApi.getFloodData(_lat!, _lng!);
        if (flood != null) {
          rawFlood = flood;
          final item = WarningItem.fromOpenMeteoFlood(flood);
          if (item != null) allInfoItems.add(item);
        }
      } catch (_) {}
    }

    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _warnings = allWarnings;
        _infoItems = allInfoItems;
        _rawAirQuality = rawAq;
        _rawFloodData = rawFlood;
        _isLoading = false;
        _isLoadingSummary = true;
      });
      _generateSummary(allWarnings);
    }
  }

  Future<void> _generateSummary(List<WarningItem> warnings) async {
    try {
      final summary = await generateLocationSummary(
        _searchController.text.split(',').first.trim(),
        warnings,
        radiusKm: _radiusKm,
        airQuality: _rawAirQuality,
        floodData: _rawFloodData,
      );
      if (mounted) setState(() { _aiSummary = summary; _isLoadingSummary = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_searchController.text.isEmpty) {
      context.showSnackBar('Enter a location first', color: AppTheme.warning);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final location = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _searchController.text.split(',').first,
      locationText: _searchController.text,
      radiusKm: _radiusKm,
      createdAt: DateTime.now(),
      latitude: _lat,
      longitude: _lng,
    );
    final success = await StorageService.saveLocation(location);
    await _loadSavedLocations();
    setState(() => _isSaving = false);
    if (mounted) context.showSnackBar(success ? 'Saved' : 'Already saved', color: success ? AppTheme.success : AppTheme.warning);
  }

  Future<void> _deleteLocation(SavedLocation loc) async {
    HapticFeedback.heavyImpact();
    await StorageService.deleteLocation(loc.id);
    await _loadSavedLocations();
    if (mounted) context.showSnackBar('${loc.name} removed', color: AppTheme.error);
  }

  void _loadLocation(SavedLocation loc) {
    HapticFeedback.selectionClick();
    setState(() {
      _searchController.text = loc.locationText;
      _radiusKm = loc.radiusKm;
      _lat = loc.latitude;
      _lng = loc.longitude;
    });
    _fetchWarnings();
  }

  List<WarningItem> get _filtered {
    if (_lat == null || _lng == null) return [];
    return _warnings.where((w) {
      if (_showOnlyActive && !w.isActive) return false;
      if (!_selectedSeverities.contains(w.severity)) return false;
      if (w.latitude != null && w.longitude != null) {
        final dist = distanceInKm(_lat!, _lng!, w.latitude!, w.longitude!);
        if (dist > _radiusKm) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _fetchWarnings,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          // Search field
          PremiumSearchField(
            controller: _searchController,
            hintText: 'Search city or location...',
            onSearch: _search,
            onMyLocation: _useMyLocation,
            onSave: _saveLocation,
            isLoading: _isLoading,
            isSaving: _isSaving,
          ),
          const SizedBox(height: 20),

          // Radius slider
          _buildRadiusSlider(),
          const SizedBox(height: 16),

          // Saved locations
          if (_savedLocations.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _savedLocations.length,
                separatorBuilder: (c, i) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final loc = _savedLocations[i];
                  return QuickChip(
                    label: loc.name,
                    icon: Icons.place_rounded,
                    onTap: () => _loadLocation(loc),
                    onLongPress: () => _deleteLocation(loc),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Loading or content
          if (_isLoading)
            const ShimmerList(count: 4)
          else ...[
            // AI Summary
            AiSummaryCard(
              summary: _aiSummary,
              isLoading: _isLoadingSummary,
              title: _searchController.text.isNotEmpty ? _searchController.text.split(',').first : 'Location Summary',
              onRefresh: () {
                HapticFeedback.selectionClick();
                setState(() => _isLoadingSummary = true);
                _generateSummary(_warnings);
              },
            ),
            const SizedBox(height: 20),

            // Stats
            if (_warnings.isNotEmpty)
              StatsRow(
                items: [
                  StatItem(label: 'Total', value: '${_warnings.length}'),
                  StatItem(label: 'Active', value: '${_warnings.where((w) => w.isActive).length}', color: AppTheme.success),
                  StatItem(label: 'In Range', value: '${filtered.length}', color: AppTheme.primary),
                ],
              ),
            if (_warnings.isNotEmpty) const SizedBox(height: 20),

            // Filters + Map button
            _buildFiltersRow(filtered),
            const SizedBox(height: 20),

            // Info items
            if (_infoItems.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _infoItems.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _buildInfoCard(_infoItems[i]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Warnings list
            if (_warnings.isEmpty)
              const EmptyStateWidget(
                icon: Icons.search_rounded,
                title: 'Search a location',
                subtitle: 'Enter a city to see nearby warnings',
              )
            else if (filtered.isEmpty)
              const EmptyStateWidget(
                icon: Icons.filter_alt_off_rounded,
                title: 'No matches',
                subtitle: 'Adjust your filters or radius',
              )
            else
              ...filtered.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WarningCard(warning: w),
              )),
          ],
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.radar_rounded, color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search Radius',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_radiusKm.toInt()} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.15),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              min: 1,
              max: 100,
              divisions: 99,
              value: _radiusKm,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _radiusKm = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(List<WarningItem> filtered) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                QuickChip(
                  label: 'Active Only',
                  icon: Icons.access_time_filled_rounded,
                  isSelected: _showOnlyActive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showOnlyActive = !_showOnlyActive);
                  },
                ),
                const SizedBox(width: 8),
                ...WarningSeverity.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: QuickChip(
                    label: s.label,
                    isSelected: _selectedSeverities.contains(s),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSeverities.contains(s)
                            ? _selectedSeverities.remove(s)
                            : _selectedSeverities.add(s);
                      });
                    },
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _lat != null && _lng != null
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onViewMap?.call(LatLng(_lat!, _lng!), _radiusKm, _warnings);
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _lat != null ? AppTheme.primaryGradient : null,
                color: _lat == null ? AppTheme.surfaceContainerHigh : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _lat != null ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                Icons.map_rounded,
                color: _lat != null ? Colors.white : AppTheme.textMuted,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(WarningItem item) {
    final isFlood = item.category == WarningCategory.flood;
    final color = isFlood ? Colors.blue : Colors.green;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isFlood ? Icons.water_rounded : Icons.eco_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
