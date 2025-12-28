import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:map_awareness/widgets/common/loading_shimmer.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/router/app_router.dart';

import 'package:map_awareness/widgets/cards/roadwork_tile.dart';
import 'package:map_awareness/widgets/cards/warning_card.dart';
import 'package:map_awareness/widgets/cards/ai_summary_card.dart';
import 'package:map_awareness/widgets/common/empty_state.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';
import 'package:map_awareness/widgets/buttons/gradient_button.dart';
import 'package:map_awareness/widgets/buttons/secondary_button.dart';
import 'package:map_awareness/widgets/inputs/location_input.dart';
import 'package:map_awareness/utils/app_theme.dart';

class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  final _startController = TextEditingController(text: 'Bremen');
  final _endController = TextEditingController(text: 'Hamburg');
  final _nameController = TextEditingController();
  
  List<SavedRoute> _savedRoutes = [];
  String? _editingId;
  bool _isSaving = false;
  bool _gettingLocation = false;

  @override
  bool get wantKeepAlive => true;

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

  Future<void> _useMyLocation() async {
    setState(() => _gettingLocation = true);
    HapticFeedback.lightImpact();
    final pos = await LocationService.getCurrentLocation();
    if (pos == null) {
      if (mounted) ToastService.warning(context, 'Location unavailable');
      setState(() => _gettingLocation = false);
      return;
    }
    final name = await GeocodingService.getPlaceName(pos.latitude, pos.longitude) ?? '${pos.latitude},${pos.longitude}';
    if (mounted) setState(() => _startController.text = name);
    setState(() => _gettingLocation = false);
  }

  Future<void> _calculateRoute() async {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      ToastService.warning(context, 'Enter start and destination');
      return;
    }

    HapticFeedback.mediumImpact();
    final success = await ref.read(routeProvider.notifier).calculate(
      _startController.text,
      _endController.text,
    );

    if (!success && mounted) {
      ToastService.error(context, 'Location not found');
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _saveRoute() async {
    final state = ref.read(routeProvider);
    if (!state.hasRoute) {
      ToastService.warning(context, 'Calculate a route first');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final route = SavedRoute(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isNotEmpty ? _nameController.text : '${state.startName} → ${state.endName}',
      startCoordinate: state.startCoords!,
      endCoordinate: state.endCoords!,
      startLocation: state.startName ?? _startController.text,
      endLocation: state.endName ?? _endController.text,
      autobahnSegments: state.autobahns,
      createdAt: DateTime.now(),
    );

    await StorageService.saveRoute(route);
    await _loadSavedRoutes();
    _nameController.clear();
    _editingId = null;
    setState(() => _isSaving = false);
    if (mounted) ToastService.success(context, 'Route saved');
  }

  Future<void> _loadRoute(SavedRoute route) async {
    HapticFeedback.selectionClick();
    _startController.text = route.startLocation;
    _endController.text = route.endLocation;
    _nameController.text = route.name;
    await _calculateRoute();
    if (mounted) ToastService.info(context, 'Loaded "${route.name}"');
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    HapticFeedback.heavyImpact();
    await StorageService.deleteRoute(route.id);
    await _loadSavedRoutes();
    if (mounted) ToastService.error(context, 'Deleted');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(routeProvider);

    return Column(
      children: [
        // Tab bar
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
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions_rounded, size: 20), SizedBox(width: 8), Text('Plan Route')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmarks_rounded, size: 20), SizedBox(width: 8), Text('Saved')])),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildPlanTab(state), _buildSavedTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTab(RouteState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editingId != null) _buildEditingBanner(),

          LocationInput(
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
                  onPressed: state.isLoading ? null : _calculateRoute,
                  isLoading: state.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(
                  label: _editingId != null ? 'Update' : 'Save',
                  icon: _editingId != null ? Icons.check_rounded : Icons.bookmark_add_rounded,
                  onPressed: state.isLoading || _isSaving || !state.hasRoute ? null : _saveRoute,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Results
          if (state.isLoading)
             const LoadingShimmer(
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   SizedBox(height: 100, child: Card(color: Colors.white)),
                   SizedBox(height: 16),
                   SizedBox(height: 150, child: Card(color: Colors.white)),
                ],
               )
             )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.roadworks.isNotEmpty) ...[
                  RoadworksSummary(roadworks: state.roadworks),
                  const SizedBox(height: 16),
                ],
                if (state.warnings.isNotEmpty) _buildWarningsSection(state),
                if (state.roadworks.isNotEmpty || state.warnings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AiSummaryCard(
                    summary: state.aiSummary,
                    isLoading: state.isSummaryLoading,
                    title: state.startName != null && state.endName != null ? '${state.startName} → ${state.endName}' : 'Summary',
                    onRefresh: () {
                      HapticFeedback.selectionClick();
                      ref.read(routeProvider.notifier).refreshSummary();
                    },
                  ),
                ],
                if (state.hasRoute) ...[
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'View on Map',
                    icon: Icons.map_rounded,
                    onPressed: () => AppRouter.goToMap(),
                    gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accentLight]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEditingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.accent.withValues(alpha: 0.15), AppTheme.accent.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Editing route', style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.9), fontWeight: FontWeight.w600))),
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

  Widget _buildWarningsSection(RouteState state) {
    return Semantics(
      excludeSemantics: true,
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          ),
          title: Text('${state.warnings.length} Warnings', style: const TextStyle(fontWeight: FontWeight.w600)),
          children: state.warnings.map((w) => Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: WarningCard(warning: w),
          )).toList(),
        ),
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

    return RefreshIndicator(
      onRefresh: _loadSavedRoutes,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('${route.autobahnSegments.length} segments', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
