import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/loading_shimmer.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/widgets/cards/warning_card.dart';
import 'package:map_awareness/widgets/cards/ai_summary_card.dart';
import 'package:map_awareness/widgets/common/empty_state.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';
import 'package:map_awareness/widgets/buttons/quick_chip.dart';
import 'package:map_awareness/widgets/inputs/location_input.dart';
import 'package:map_awareness/widgets/feedback/stats_row.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/string_utils.dart';

/// Screen for searching and viewing localized safety warnings and environmental data.
class WarningsScreen extends ConsumerStatefulWidget {
  const WarningsScreen({super.key});

  @override
  ConsumerState<WarningsScreen> createState() => _WarningsScreenState();
}

/// State for WarningsScreen managing search controllers and selected filters.
class _WarningsScreenState extends ConsumerState<WarningsScreen> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final Set<WarningSeverity> _selectedSeverities = {...WarningSeverity.values};

  List<SavedLocation> _savedLocations = [];
  bool _isSaving = false;
  bool _showOnlyActive = false;

  @override
  bool get wantKeepAlive => true;

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

  /// Updates search field and state with the current device location.
  Future<void> _useMyLocation() async {
    Haptics.light();
    final pos = await LocationService.getCurrentLocation();
    if (pos == null) {
      if (mounted) ToastService.warning(context, 'Location unavailable');
      return;
    }
    final coordStr = '${pos.latitude},${pos.longitude}';
    await ref.read(warningProvider.notifier).setLocation(
      pos.latitude,
      pos.longitude,
      'My Location ($coordStr)',
    );
    _searchController.text = 'My Location ($coordStr)';
  }

  /// Executes a geocoding search for the entered location text.
  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      ToastService.warning(context, 'Enter a location first');
      return;
    }
    Haptics.medium();
    final success = await ref.read(warningProvider.notifier).search(_searchController.text);
    if (!success && mounted) {
      ToastService.error(context, 'Location not found');
    } else {
      final state = ref.read(warningProvider);
      _searchController.text = state.locationText ?? _searchController.text;
      Haptics.heavy();
    }
  }

  /// Persists the current location and radius settings.
  Future<void> _saveLocation() async {
    final state = ref.read(warningProvider);
    if (_searchController.text.isEmpty) {
      ToastService.warning(context, 'Enter a location first');
      return;
    }
    Haptics.medium();
    setState(() => _isSaving = true);
    final location = SavedLocation(
      id: clock.now().millisecondsSinceEpoch.toString(),
      name: _searchController.text.cityName,
      locationText: _searchController.text,
      radiusKm: state.radiusKm,
      createdAt: clock.now(),
      latitude: state.lat,
      longitude: state.lng,
    );
    final success = await StorageService.saveLocation(location);
    await _loadSavedLocations();
    setState(() => _isSaving = false);
    if (mounted) ToastService.success(context, success ? 'Saved' : 'Already saved');
  }

  Future<void> _deleteLocation(SavedLocation loc) async {
    Haptics.heavy();
    await StorageService.deleteLocation(loc.id);
    await _loadSavedLocations();
    if (mounted) ToastService.error(context, '${loc.name} removed');
  }

  /// Applies a saved location to the state and search field.
  void _loadLocation(SavedLocation loc) {
    Haptics.select();
    _searchController.text = loc.locationText;
    ref.read(warningProvider.notifier).setRadius(loc.radiusKm);
    if (loc.latitude != null && loc.longitude != null) {
      ref.read(warningProvider.notifier).setLocation(loc.latitude!, loc.longitude!, loc.locationText);
    }
  }

  /// Filters warnings based on active status, severity, and distance from center.
  List<WarningItem> _filterWarnings(WarningState state) {
    if (!state.hasLocation) return [];
    return state.warnings.where((w) {
      if (_showOnlyActive && !w.isActive) return false;
      if (!_selectedSeverities.contains(w.severity)) return false;
      if (w.latitude != null && w.longitude != null) {
        final dist = LocationService.distanceInKm(state.lat!, state.lng!, w.latitude!, w.longitude!);
        if (dist > state.radiusKm) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(warningProvider);
    final filtered = _filterWarnings(state);

    // Dismiss keyboard on tap outside input fields.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: RefreshIndicator(
        onRefresh: () => ref.read(warningProvider.notifier).refresh(),
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
          SearchField(
            controller: _searchController,
            hintText: 'Search city or location...',
            onSearch: _search,
            onMyLocation: _useMyLocation,
            onSave: _saveLocation,
            isLoading: state.isLoading,
            isSaving: _isSaving,
          ),
          const SizedBox(height: 20),

          _buildRadiusSlider(state),
          const SizedBox(height: 16),

          if (_savedLocations.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _savedLocations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final loc = _savedLocations[i];
                  return QuickChip(label: loc.name, icon: Icons.place_rounded, onTap: () => _loadLocation(loc), onLongPress: () => _deleteLocation(loc));
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (state.isLoading)
            SkeletonLayouts.warnings()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.currentWeather != null) ...[
                  _buildWeatherCard(state),
                  const SizedBox(height: 16),
                ],
                AiSummaryCard(
                  summary: state.aiSummary,
                  isLoading: state.isSummaryLoading,
                  title: state.locationText?.cityName ?? 'Location Summary',
                  onRefresh: () {
                    Haptics.select();
                    ref.read(warningProvider.notifier).refreshSummary();
                  },
                ),
                const SizedBox(height: 20),

                if (state.warnings.isNotEmpty)
                  StatsRow(items: [
                    StatItem(label: 'Total', value: '${state.warnings.length}'),
                    StatItem(label: 'Active', value: '${state.warnings.where((w) => w.isActive).length}', color: Colors.green),
                    StatItem(label: 'In Range', value: '${filtered.length}', color: AppTheme.primary),
                  ]),
                if (state.warnings.isNotEmpty) const SizedBox(height: 20),

                _buildFiltersRow(state, filtered),
                const SizedBox(height: 20),

                if (state.infoItems.isNotEmpty) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive switch.
                      final useRow = constraints.maxWidth > 500 && state.infoItems.length > 1;
                      if (useRow) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.infoItems.map((item) => Expanded(child: Padding(
                            padding: EdgeInsets.only(right: item == state.infoItems.last ? 0 : 12),
                            child: _buildInfoCard(item),
                          ))).toList(),
                        );
                      }
                      return Column(
                        children: state.infoItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInfoCard(item),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                if (state.warnings.isEmpty)
                  const EmptyStateWidget(icon: Icons.search_rounded, title: 'Search a location', subtitle: 'Enter a city to see nearby warnings')
                else if (filtered.isEmpty)
                  const EmptyStateWidget(icon: Icons.filter_alt_off_rounded, title: 'No matches', subtitle: 'Adjust your filters or radius')
                else
                  ...filtered.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: WarningCard(warning: w))),
              ],
            ),
        ],
        ),
      ),
    );
  }

  /// Builds a slider component for adjusting the geographic search radius.
  Widget _buildRadiusSlider(WarningState state) {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.radar_rounded, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Search Radius', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]), borderRadius: BorderRadius.circular(20)),
                child: Text('${state.radiusKm.toInt()} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
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
              min: 1, max: 100, divisions: 99, value: state.radiusKm,
              onChanged: (v) {
                Haptics.select();
                ref.read(warningProvider.notifier).setRadius(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row containing filter chips for warnings.
  Widget _buildFiltersRow(WarningState state, List<WarningItem> filtered) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          QuickChip(
            label: 'Active Only',
            icon: Icons.access_time_filled_rounded,
            isSelected: _showOnlyActive,
            onTap: () {
              Haptics.select();
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
                Haptics.select();
                setState(() => _selectedSeverities.contains(s) ? _selectedSeverities.remove(s) : _selectedSeverities.add(s));
              },
            ),
          )),
        ],
      ),
    );
  }

  /// Builds a card displaying environmental info like flood risk or air quality.
  Widget _buildInfoCard(WarningItem item) {
    final isFlood = item.category == WarningCategory.flood;
    final color = isFlood ? Colors.blue : Colors.green;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isFlood ? Icons.water_rounded : Icons.eco_rounded, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card displaying current weather conditions.
  Widget _buildWeatherCard(WarningState state) {
    final weather = state.currentWeather!;
    const color = AppTheme.accent;
    
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(weather.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Weather', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '${weather.temperature?.toStringAsFixed(1) ?? '--'}°C · ${weather.description}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
          if (weather.windSpeed != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.air, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text('${weather.windSpeed!.toStringAsFixed(0)} km/h', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
