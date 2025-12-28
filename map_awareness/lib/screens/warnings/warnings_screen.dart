import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/widgets/common/loading_shimmer.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/widgets/cards/warning_card.dart';
import 'package:map_awareness/widgets/cards/ai_summary_card.dart';
import 'package:map_awareness/widgets/common/empty_state.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';
import 'package:map_awareness/widgets/buttons/quick_chip.dart';
import 'package:map_awareness/widgets/inputs/location_input.dart';
import 'package:map_awareness/widgets/feedback/stats_row.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/string_utils.dart';

class WarningsScreen extends ConsumerStatefulWidget {
  const WarningsScreen({super.key});

  @override
  ConsumerState<WarningsScreen> createState() => _WarningsScreenState();
}

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

  Future<void> _useMyLocation() async {
    HapticFeedback.lightImpact();
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

  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      ToastService.warning(context, 'Enter a location first');
      return;
    }
    HapticFeedback.mediumImpact();
    final success = await ref.read(warningProvider.notifier).search(_searchController.text);
    if (!success && mounted) {
      ToastService.error(context, 'Location not found');
    } else {
      final state = ref.read(warningProvider);
      _searchController.text = state.locationText ?? _searchController.text;
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _saveLocation() async {
    final state = ref.read(warningProvider);
    if (_searchController.text.isEmpty) {
      ToastService.warning(context, 'Enter a location first');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final location = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _searchController.text.cityName,
      locationText: _searchController.text,
      radiusKm: state.radiusKm,
      createdAt: DateTime.now(),
      latitude: state.lat,
      longitude: state.lng,
    );
    final success = await StorageService.saveLocation(location);
    await _loadSavedLocations();
    setState(() => _isSaving = false);
    if (mounted) ToastService.success(context, success ? 'Saved' : 'Already saved');
  }

  Future<void> _deleteLocation(SavedLocation loc) async {
    HapticFeedback.heavyImpact();
    await StorageService.deleteLocation(loc.id);
    await _loadSavedLocations();
    if (mounted) ToastService.error(context, '${loc.name} removed');
  }

  void _loadLocation(SavedLocation loc) {
    HapticFeedback.selectionClick();
    _searchController.text = loc.locationText;
    ref.read(warningProvider.notifier).setRadius(loc.radiusKm);
    if (loc.latitude != null && loc.longitude != null) {
      ref.read(warningProvider.notifier).setLocation(loc.latitude!, loc.longitude!, loc.locationText);
    }
  }

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

    return RefreshIndicator(
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
             const LoadingShimmer(
               child: Column(
                children: [
                   SizedBox(height: 120, child: Card(color: Colors.white)),
                   SizedBox(height: 20),
                   SizedBox(height: 80, child: Card(color: Colors.white)),
                   SizedBox(height: 20),
                   SizedBox(height: 200, child: Card(color: Colors.white)),
                ],
               )
             )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AiSummaryCard(
                  summary: state.aiSummary,
                  isLoading: state.isSummaryLoading,
                  title: state.locationText?.cityName ?? 'Location Summary',
                  onRefresh: () {
                    HapticFeedback.selectionClick();
                    ref.read(warningProvider.notifier).refreshSummary();
                  },
                ),
                const SizedBox(height: 20),

                if (state.warnings.isNotEmpty)
                  StatsRow(items: [
                    StatItem(label: 'Total', value: '${state.warnings.length}'),
                    StatItem(label: 'Active', value: '${state.warnings.where((w) => w.isActive).length}', color: AppTheme.success),
                    StatItem(label: 'In Range', value: '${filtered.length}', color: AppTheme.primary),
                  ]),
                if (state.warnings.isNotEmpty) const SizedBox(height: 20),

                _buildFiltersRow(state, filtered),
                const SizedBox(height: 20),

                if (state.infoItems.isNotEmpty) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // responsive: single column if narrow, row if wide
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
    );
  }

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
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
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
                HapticFeedback.selectionClick();
                ref.read(warningProvider.notifier).setRadius(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(WarningState state, List<WarningItem> filtered) {
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
                      setState(() => _selectedSeverities.contains(s) ? _selectedSeverities.remove(s) : _selectedSeverities.add(s));
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
            onTap: state.hasLocation ? () {
              HapticFeedback.mediumImpact();
              AppRouter.goToMap();
            } : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: state.hasLocation ? AppTheme.primaryGradient : null,
                color: !state.hasLocation ? AppTheme.surfaceContainerHigh : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: state.hasLocation ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Icon(Icons.map_rounded, color: state.hasLocation ? Colors.white : AppTheme.textMuted, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(WarningItem item) {
    final isFlood = item.category == WarningCategory.flood;
    final color = isFlood ? AppTheme.info : AppTheme.success;
    
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
                Text(item.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
