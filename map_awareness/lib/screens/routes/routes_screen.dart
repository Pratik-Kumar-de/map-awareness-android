import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/components/loading/shimmer_loading.dart';
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
import 'package:map_awareness/widgets/empty_state.dart';
import 'package:map_awareness/widgets/premium_inputs.dart';
import 'package:map_awareness/widgets/app_navigation.dart';
import 'package:map_awareness/utils/snackbar_utils.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/premium_card.dart';

/// Routes screen with premium UI
class RoutesScreen extends StatefulWidget {
  final void Function(List<PointLatLng> polyline, List<LatLng> roadworkPoints, [List<List<RoutingWidgetData>>? roadworks])? onRouteCalculated;
  final void Function(int tabIndex)? onTabRequested;

  const RoutesScreen({super.key, this.onRouteCalculated, this.onTabRequested});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _startController = TextEditingController(text: 'Bremen');
  final _endController = TextEditingController(text: 'Hamburg');
  final _nameController = TextEditingController();

  List<SavedRoute> _savedRoutes = [];
  List<List<RoutingWidgetData>> _roadworks = [];
  List<AutobahnClass> _autobahnList = [];
  List<PointLatLng> _polylinePoints = [];
  List<WarningItem> _routeWarnings = [];
  String? _startCoords, _endCoords, _startName, _endName;
  String? _editingId, _aiSummary;
  bool _isLoading = false, _isSaving = false, _isLoadingSummary = false, _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedRoutes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startController.dispose();
    _endController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await StorageService.loadRoutes();
    setState(() => _savedRoutes = routes);
  }

  Future<String?> _geocode(String address) async {
    if (RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(address.trim())) {
      return address.trim().replaceAll(' ', '');
    }
    final results = await geocode(address, limit: 1);
    return results.isNotEmpty ? results.first.coordinates : null;
  }

  Future<String> _resolveName(String input) async {
    final match = RegExp(r'^(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)$').firstMatch(input.trim());
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(3)!);
      if (lat != null && lng != null) {
        return await reverseGeocode(lat, lng) ?? input;
      }
    }
    return input;
  }

  Future<void> _useMyLocation() async {
    setState(() => _gettingLocation = true);
    HapticFeedback.lightImpact();
    final coords = await getCurrentUserLocation();
    if (coords == null) {
      if (mounted) context.showSnackBar('Location unavailable', color: AppTheme.warning);
      setState(() => _gettingLocation = false);
      return;
    }
    final parts = coords.split(',');
    final name = await reverseGeocode(double.parse(parts[0]), double.parse(parts[1]));
    if (mounted) setState(() => _startController.text = name ?? coords);
    setState(() => _gettingLocation = false);
  }

  Future<void> _calculateRoute() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      context.showSnackBar('Enter start and destination', color: AppTheme.warning);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() { _isLoading = true; _aiSummary = null; });

    try {
      final startCoords = await _geocode(_startController.text);
      final endCoords = await _geocode(_endController.text);
      if (startCoords == null || endCoords == null) {
        if (mounted) context.showSnackBar('Location not found', color: AppTheme.error);
        setState(() => _isLoading = false);
        return;
      }

      final routeResult = await routingWithPolyline(startCoords, endCoords);
      final roadworks = await getRoutingWidgetData(startCoords, endCoords);

      final warnings = <WarningItem>[];
      try {
        warnings.addAll((await getAllDWDWarnings()).map(WarningItem.fromDWD));
        final startCity = _startController.text.split(',').first.trim();
        final endCity = _endController.text.split(',').first.trim();
        warnings.addAll((await getNINAWarningsForCity(startCity)).map(WarningItem.fromNINA));
        if (startCity.toLowerCase() != endCity.toLowerCase()) {
          warnings.addAll((await getNINAWarningsForCity(endCity)).map(WarningItem.fromNINA));
        }
        final seen = <String>{};
        warnings.removeWhere((w) => !seen.add(w.title));
      } catch (_) {}

      final startName = await _resolveName(_startController.text);
      final endName = await _resolveName(_endController.text);

      HapticFeedback.heavyImpact();
      setState(() {
        _autobahnList = routeResult.autobahnList;
        _polylinePoints = routeResult.polylinePoints;
        _roadworks = roadworks;
        _routeWarnings = warnings..sort();
        _startCoords = startCoords;
        _endCoords = endCoords;
        _startName = startName;
        _endName = endName;
        _isLoading = false;
        _isLoadingSummary = true;
      });

      final roadworkLatLngs = roadworks.expand((l) => l)
          .where((r) => r.latitude != null && r.longitude != null)
          .map((r) => LatLng(r.latitude!, r.longitude!))
          .toList();
      widget.onRouteCalculated?.call(routeResult.polylinePoints, roadworkLatLngs, roadworks);

      _generateSummary([...roadworks[0], ...roadworks[1], ...roadworks[2]], warnings);
    } catch (e) {
      if (mounted) context.showSnackBar('Error: $e', color: AppTheme.error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSummary(List<RoutingWidgetData> roadworks, List<WarningItem> warnings) async {
    try {
      final summary = await generateRouteSummary(roadworks, warnings, _startName ?? '', _endName ?? '');
      if (mounted) setState(() { _aiSummary = summary; _isLoadingSummary = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _saveRoute() async {
    if (_autobahnList.isEmpty) {
      context.showSnackBar('Calculate a route first', color: AppTheme.warning);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final route = SavedRoute(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isNotEmpty ? _nameController.text : '$_startName → $_endName',
      startCoordinate: _startCoords!,
      endCoordinate: _endCoords!,
      startLocation: _startName ?? _startController.text,
      endLocation: _endName ?? _endController.text,
      autobahnSegments: autobahnClassToData(_autobahnList),
      createdAt: DateTime.now(),
    );

    await StorageService.saveRoute(route);
    await _loadSavedRoutes();
    _nameController.clear();
    _editingId = null;
    setState(() => _isSaving = false);
    if (mounted) context.showSnackBar('Route saved', color: AppTheme.success);
  }

  Future<void> _loadRoute(SavedRoute route) async {
    HapticFeedback.selectionClick();
    _startController.text = route.startLocation;
    _endController.text = route.endLocation;
    _nameController.text = route.name;
    await _calculateRoute();
    if (mounted) context.showSnackBar('Loaded "${route.name}"');
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    HapticFeedback.heavyImpact();
    await StorageService.deleteRoute(route.id);
    await _loadSavedRoutes();
    if (mounted) context.showSnackBar('Deleted', color: AppTheme.error);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar with premium styling
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: AppTheme.cardShadow,
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Plan Route'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmarks_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Saved'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildPlanTab(), _buildSavedTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editing banner
          if (_editingId != null) _buildEditingBanner(),

          // Location input
          PremiumLocationInput(
            startController: _startController,
            endController: _endController,
            isGettingLocation: _gettingLocation,
            onMyLocation: _useMyLocation,
            onSwap: () {
              HapticFeedback.selectionClick();
              final t = _startController.text;
              _startController.text = _endController.text;
              _endController.text = t;
            },
          ),
          const SizedBox(height: 16),

          // Route name input
          PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: TextField(
              controller: _nameController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Route name (optional)',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.label_outline_rounded, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'Calculate Route',
                  icon: Icons.directions_rounded,
                  onPressed: _isLoading ? null : _calculateRoute,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: _editingId != null ? 'Update' : 'Save',
                  icon: _editingId != null ? Icons.check_rounded : Icons.bookmark_add_rounded,
                  onPressed: _isLoading || _isSaving || _autobahnList.isEmpty ? null : _saveRoute,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Results
          if (_isLoading)
            const ShimmerList(count: 3)
          else ...[
            if (_roadworks.isNotEmpty) ...[
              RoadworksSummary(roadworks: _roadworks),
              const SizedBox(height: 16),
            ],
            if (_routeWarnings.isNotEmpty)
              _buildWarningsSection(),
            if (_roadworks.isNotEmpty || _routeWarnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              AiSummaryCard(
                summary: _aiSummary,
                isLoading: _isLoadingSummary,
                title: _startName != null && _endName != null ? '$_startName → $_endName' : 'Summary',
                onRefresh: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isLoadingSummary = true);
                  _generateSummary([..._roadworks[0], ..._roadworks[1], ..._roadworks[2]], _routeWarnings);
                },
              ),
            ],
            if (_polylinePoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              GradientButton(
                label: 'View on Map',
                icon: Icons.map_rounded,
                onPressed: () => widget.onTabRequested?.call(2),
                gradient: LinearGradient(
                  colors: [AppTheme.accent, AppTheme.accentLight],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEditingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.15),
            AppTheme.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editing route',
              style: TextStyle(
                color: AppTheme.accent.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() { _editingId = null; _nameController.clear(); });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection() {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
        ),
        title: Text(
          '${_routeWarnings.length} Warnings',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: _routeWarnings.map((w) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: WarningCard(warning: w),
        )).toList(),
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedRoutes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved routes',
        subtitle: 'Calculate and save a route to see it here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _savedRoutes.length,
      itemBuilder: (context, i) {
        final route = _savedRoutes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _startController.text = route.startLocation;
                      _endController.text = route.endLocation;
                      _nameController.text = route.name;
                      _editingId = route.id;
                    });
                    _tabController.animateTo(0);
                  },
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
                SlidableAction(
                  onPressed: (_) => _deleteRoute(route),
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                ),
              ],
            ),
            child: PremiumCard(
              onTap: () {
                _loadRoute(route);
                _tabController.animateTo(0);
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${route.autobahnSegments.length} segments',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
