import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/bottom_sheet.dart';
import 'package:map_awareness/router/app_router.dart';
import 'package:map_awareness/widgets/common/map_details_sheet.dart';
import 'package:map_awareness/widgets/common/glass_container.dart';
import 'package:map_awareness/widgets/common/map_marker.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/cards/route_comparison_sheet.dart';


/// Screen displaying the interactive map with route polylines and event markers.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}


/// State for MapScreen handling map controller and reactive fitting.
class _MapScreenState extends ConsumerState<MapScreen> with AutomaticKeepAliveClientMixin {
  final _mapController = MapController();
  static const _defaultCenter = LatLng(51.1657, 10.4515);
  static const _defaultZoom = 6.0;
  
  String? _activePopupKey;
  bool _mapReady = false;
  LatLng? _tempStartPoint;
  bool _showRadius = false; // Toggles radius circle visibility on map.
  
  // Route creation mode: 0 = off, 1 = picking start, 2 = picking destination.
  int _routeStep = 0;

  @override
  bool get wantKeepAlive => true;



  void _onMapReady() {
    _mapReady = true;
    final routeState = ref.read(routeProvider);
    final warningState = ref.read(warningProvider);
    
    if (routeState.hasRoute) {
      _fitToRoute(routeState.polyline);
    } else if (warningState.center != null) {
      _fitToRadius(warningState.center!, warningState.radiusKm);
    }
  }

  /// Adjusts camera to fit the given list of polyline coordinates.
  void _fitToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(50)),
    );
  }

  /// Adjusts camera to center on a point with a specific radius.
  void _fitToRadius(LatLng center, double radiusKm) {
    _mapController.move(center, _zoomForRadius(radiusKm));
  }

  /// Maps kilometer radius to an appropriate map zoom level.
  double _zoomForRadius(double r) {
    if (r > 80) return 7.0;
    if (r > 40) return 8.0;
    if (r > 20) return 9.0;
    if (r > 10) return 10.0;
    return 11.0;
  }

  /// Recenters the camera based on current route or radius state.
  void _recenter() {
    final routeState = ref.read(routeProvider);
    final warningState = ref.read(warningProvider);
    
    if (routeState.hasRoute) {
      _fitToRoute(routeState.polyline);
    } else if (warningState.center != null) {
      _fitToRadius(warningState.center!, warningState.radiusKm);
    }
  }

  /// Closes any active popup (if dismissible) and shows the new sheet, tracking its key.
  void _dismissAndShow(String key, Widget sheet) {
    if (_activePopupKey != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _activePopupKey = key;
    showAppSheet(context, child: sheet);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    ref.listen(routeProvider.select((s) => s.polyline), (_, polyline) {
      if (_mapReady && polyline.isNotEmpty) {
        _fitToRoute(polyline);
      }
    });

    // Note: Removed auto-center on warningState.center change - radius toggle controls visibility only.

    final routeState = ref.watch(routeProvider);
    final warningState = ref.watch(warningProvider);
    final cs = Theme.of(context).colorScheme;

    final hasRoute = routeState.hasRoute;
    final hasWarningLocation = warningState.hasLocation; // For radius button visibility.
    final isRadiusMode = hasWarningLocation && !hasRoute; // For map centering priority.
    final showRadius = hasWarningLocation && warningState.showRadiusCircle;
    final center = isRadiusMode ? warningState.center : routeState.polyline.firstOrNull;

    return Material(
      color: cs.surface,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center ?? _defaultCenter,
              initialZoom: isRadiusMode ? _zoomForRadius(warningState.radiusKm) : _defaultZoom,
              onMapReady: _onMapReady,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                 onTap: (tapPos, point) async {
                   // Route creation mode: handles step-by-step.
                   if (_routeStep > 0) {
                     await _handleRouteTap(point);
                     return;
                   }
                   
                   // Dismisses active popup.
                   if (mounted && _activePopupKey != null && Navigator.of(context).canPop()) {
                     Navigator.of(context).pop();
                     _activePopupKey = null;
                   }
                 },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.map_awareness.app',
                retinaMode: MediaQuery.devicePixelRatioOf(context) > 1.0,
              ),
              if (_showRadius && warningState.center != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: warningState.center!,
                    radius: warningState.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderColor: AppTheme.primary,
                    borderStrokeWidth: 2.5,
                  ),
                ]),
              
              // Alternative Routes (tappable).
              if (hasRoute && routeState.availableRoutes.length > 1)
                GestureDetector(
                  onTapDown: (_) => _showRouteComparison(),
                  child: PolylineLayer(polylines: [
                    for (var i = 0; i < routeState.availableRoutes.length; i++)
                      if (i != routeState.selectedRouteIndex)
                        Polyline(
                          points: routeState.availableRoutes[i].coordinates,
                          color: Colors.black.withValues(alpha: 0.4),
                          strokeWidth: 8, // Wider for easier tap.
                          borderColor: Colors.white.withValues(alpha: 0.5),
                          borderStrokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                  ]),
                ),

              if (hasRoute)
                PolylineLayer(polylines: [
                  Polyline(
                    points: routeState.polyline,
                    color: AppTheme.primary,
                    strokeWidth: 5,
                    borderColor: Colors.black.withValues(alpha: 0.6),
                    borderStrokeWidth: 1,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ]),
              MarkerLayer(markers: _buildMarkers(routeState, warningState, hasRoute, isRadiusMode)),
            ],
          ),

          // Map controls.
          Positioned(
            right: AppTheme.spacingMd,
            bottom: 100,
            child: _MapControls(
              onZoomIn: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
              onZoomOut: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
              onRecenter: (hasRoute || isRadiusMode) ? _recenter : null,
            ),
          ),

          // Route creation instruction pill.
          if (_routeStep > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppTheme.spacingMd,
              left: 0,
              right: 0,
              child: _RouteInstructionPill(step: _routeStep),
            ),

          // Top right controls: Layer toggles and Route Creation button.
          Positioned(
            top: MediaQuery.of(context).padding.top + AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Route layer toggles.
                if (hasRoute) ...[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _LayerChip(
                      label: 'Parking',
                      icon: Icons.local_parking,
                      active: routeState.showParking,
                      onTap: () => ref.read(routeProvider.notifier).toggleParking(),
                    ),
                    const SizedBox(width: 8),
                    _LayerChip(
                      label: 'EV Charging',
                      icon: Icons.ev_station,
                      active: routeState.showCharging,
                      onTap: () => ref.read(routeProvider.notifier).toggleCharging(),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
                // Radius toggle when warning location is set.
                if (hasWarningLocation) ...[
                  _LayerChip(
                    label: 'Warning Area',
                    icon: Icons.radar_rounded,
                    active: warningState.showRadiusCircle,
                    onTap: () => ref.read(warningProvider.notifier).toggleRadiusCircle(),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisSize: MainAxisSize.min, children: [
                  // Radius toggle: only if a location is selected.
                  if (warningState.hasLocation) ...[
                    _LayerChip(
                      label: 'Radius',
                      icon: Icons.radar_rounded,
                      active: _showRadius,
                      onTap: () => setState(() => _showRadius = !_showRadius),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _RouteCreationButton(
                    isActive: _routeStep > 0,
                    onTap: _routeStep > 0 ? _cancelRouteCreation : _startRouteCreation,
                  ),
                ]),
              ],
            ),
          ),
            
           // Handles left-edge swipe.
           Positioned(
             left: 0, top: 0, bottom: 0, width: 24,
             child: GestureDetector(
               behavior: HitTestBehavior.translucent,
               onHorizontalDragEnd: (details) {
                 if (details.primaryVelocity! > 300) { // Fast swipe right
                   Haptics.select();
                   AppRouter.goToWarnings();
                 }
               },
               child: Container(color: Colors.transparent),
             ),
             ),
        ],
      ),
    );
  }

  /// Aggregates and builds all map markers (route, events, warnings) based on current state.
  List<Marker> _buildMarkers(RouteState routeState, WarningState warningState, bool hasRoute, bool isRadiusMode) {
    final markers = <Marker>[];

    // Temporary start marker (during creation).
    if (_tempStartPoint != null) {
      markers.add(_marker(_tempStartPoint!, const MapMarker.small(icon: Icons.circle, color: Colors.green)));
    }

    // Route markers.
    if (hasRoute && routeState.polyline.isNotEmpty) {
      markers.add(_marker(routeState.polyline.first, const MapMarker.small(icon: Icons.circle, color: Colors.green)));
      markers.add(_marker(routeState.polyline.last, MapMarker.small(icon: Icons.flag_rounded, color: AppTheme.error)));
    }

    // Radius marker (shown when radius toggle is active).
    if (_showRadius && warningState.center != null) {
      markers.add(_marker(warningState.center!, MapMarker.small(icon: Icons.my_location, color: AppTheme.primary)));
    }

    // Charging stations.
    if (routeState.showCharging) {
      markers.addAll(_entityMarkers(
        items: routeState.chargingStations,
        id: (i) => 'cs_${i.identifier}',
        location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (_) => Icons.ev_station,
        color: (_) => Colors.green.withValues(alpha: 0.85),
        sheet: _chargingSheet,
        size: 24,
      ));
    }

    // Parking areas.
    if (routeState.showParking) {
      markers.addAll(_entityMarkers(
        items: routeState.parkingAreas,
        id: (i) => 'pk_${i.identifier}',
        location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (_) => Icons.local_parking,
        color: (_) => Colors.blue.withValues(alpha: 0.8),
        sheet: _parkingSheet,
        size: 22,
      ));
    }

    // Roadworks with theme-aware colors.
    if (routeState.roadworks.isNotEmpty) {
      markers.addAll(_entityMarkers(
        items: routeState.roadworks.expand((l) => l),
        id: (i) => 'rw_${i.identifier}',
        location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (i) => i.isBlocked ? Icons.block : Icons.construction,
        color: (i) => (i.isBlocked ? AppTheme.error : const Color(0xFFF57C00)).withValues(alpha: 0.85),
        sheet: _roadworkSheet,
      ));
    }

    // Warnings.
    markers.addAll(_entityMarkers(
      items: isRadiusMode ? warningState.warnings : routeState.warnings,
      id: (i) => 'wn_${i.title.hashCode}',
      location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
      icon: (_) => Icons.warning_amber_rounded,
      color: (i) => i.severity.color.withValues(alpha: 0.85),
      sheet: _warningSheet,
      size: 26,
    ));

    return markers;
  }

  /// Helper to create a basic Marker widget.
  Marker _marker(LatLng point, Widget child, {double size = 28}) =>
      Marker(point: point, width: size, height: size, child: child);

  /// Generic builder for creating a list of markers from a list of data items.
  Iterable<Marker> _entityMarkers<T>({
    required Iterable<T> items,
    required String Function(T) id,
    required LatLng? Function(T) location,
    required IconData Function(T) icon,
    required Color Function(T) color,
    required Widget Function(T) sheet,
    double size = 28,
  }) {
    return items.map((item) {
      final loc = location(item);
      if (loc == null) return null;
      return Marker(
        point: loc,
        width: size,
        height: size,
        child: MapMarker(
          icon: icon(item),
          backgroundColor: color(item),
          onTap: () => _dismissAndShow(id(item), sheet(item)),
        ),
      );
    }).whereType<Marker>();
  }

  // Sheet builders.
  /// Builds a details sheet for a charging station.
  Widget _chargingSheet(ChargingStationDto cs) => MapDetailsSheet(
    icon: Icons.ev_station,
    color: Colors.green,
    title: cs.title,
    subtitle: cs.subtitle,
    description: cs.descriptionText,
  );

  /// Builds a details sheet for a parking area.
  Widget _parkingSheet(ParkingDto p) => MapDetailsSheet(
    icon: Icons.local_parking,
    color: Colors.blue,
    title: p.title,
    subtitle: p.subtitle,
    description: p.descriptionText,
    additionalChips: p.isLorryParking ? [
      Chip(
        avatar: const Icon(Icons.local_shipping, size: 16, color: Colors.blue),
        label: const Text('Lorry parking'),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        side: BorderSide.none,
      ),
    ] : null,
  );

  /// Builds a details sheet for a roadwork event.
  Widget _roadworkSheet(RoadworkDto rw) {
    final cs = Theme.of(context).colorScheme;
    final c = rw.isBlocked ? cs.error : cs.tertiary;
    return MapDetailsSheet(
      icon: rw.isBlocked ? Icons.block : Icons.construction,
      color: c,
      title: rw.title,
      subtitle: rw.subtitle,
      description: rw.descriptionText,
      additionalChips: [
        if (rw.isBlocked)
          Chip(avatar: Icon(Icons.block, size: 16, color: c), label: const Text('Road blocked'), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        Chip(avatar: Icon(Icons.access_time, size: 16, color: c), label: Text(rw.timeInfo), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        if (rw.length != null)
          Chip(label: Text(rw.length!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        if (rw.speedLimit != null)
          Chip(avatar: Icon(Icons.speed, size: 16, color: c), label: Text(rw.speedLimit!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
      ],
    );
  }

  /// Builds a details sheet for a warning item.
  Widget _warningSheet(WarningItem w) => MapDetailsSheet(
    icon: Icons.warning_amber_rounded,
    color: w.severity.color,
    title: w.title,
    subtitle: '${w.severity.label} • ${w.source}',
    description: w.description,
    additionalChips: [
      Chip(
        avatar: Icon(Icons.schedule, size: 16, color: w.severity.color),
        label: Text(w.formattedTimeRange),
        backgroundColor: w.severity.color.withValues(alpha: 0.1),
        side: BorderSide.none,
      ),
    ],
  );

  /// Starts route creation mode.
  void _startRouteCreation() {
    Haptics.medium();
    setState(() {
      _routeStep = 1;
      _tempStartPoint = null;
    });
    // Clears any previous input.
    ref.read(routeInputProvider.notifier).setStart('');
    ref.read(routeInputProvider.notifier).setEnd('');
  }

  
  /// Cancels route creation mode.
  void _cancelRouteCreation() {
    Haptics.light();
    setState(() {
      _routeStep = 0;
      _tempStartPoint = null;
    });
  }
  
  /// Handles map tap during route creation.
  Future<void> _handleRouteTap(LatLng point) async {
    Haptics.select();
    
    // Uses exact coordinates for routing precision.
    final coordString = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    
    // Tries to get a human-readable name just for user feedback (Toast).
    String displayName = coordString;
    try {
      final name = await GeocodingService.getPlaceName(point.latitude, point.longitude);
      if (name != null) displayName = name;
    } catch (_) {}
    
    if (!mounted) return;
    
    if (_routeStep == 1) {
      // First tap: set start.
      Haptics.medium();
      ref.read(routeInputProvider.notifier).setStart(displayName);
      setState(() {
        _routeStep = 2;
        _tempStartPoint = point;
      });
      ToastService.info(context, 'Start: $displayName');
    } else if (_routeStep == 2) {
      // Second tap: set destination and calculate.
      Haptics.heavy();
      ref.read(routeInputProvider.notifier).setEnd(displayName);
      setState(() {
        _routeStep = 0;
        _tempStartPoint = null;
      });
      
      // Auto-calculate route.
      final success = await ref.read(routeProvider.notifier).calculate(
        ref.read(routeInputProvider).start,
        displayName,
      );
      
      if (mounted) {
        if (success) {
          ToastService.success(context, 'Route calculated!');
        } else {
          ToastService.error(context, 'Route failed');
        }
      }
    }
  }
  
  /// Shows route comparison sheet.
  void _showRouteComparison() {
    Haptics.medium();
    showAppSheet(context, child: const RouteComparisonSheet());
  }
}

// Map control buttons.
/// Overlay buttons for map camera control.
class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onRecenter;

  const _MapControls({required this.onZoomIn, required this.onZoomOut, this.onRecenter});

  @override
  Widget build(BuildContext context) {
    // Uses GlassContainer default theme-aware colors.
    return GlassContainer(
      padding: EdgeInsets.zero,
      // Default radius is 12 (AppTheme.radiusSm) and blur is 8, matching other controls.
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _ControlButton(icon: Icons.add, onTap: onZoomIn),
        _Divider(),
        _ControlButton(icon: Icons.remove, onTap: onZoomOut),
        if (onRecenter != null) ...[_Divider(), _ControlButton(icon: Icons.center_focus_strong, onTap: onRecenter!)],
      ]),
    );
  }
}

/// Reusable icon button for map controls.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Simple vertical divider for control buttons.
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08));
  }
}

// Layer toggle chip.
/// Toggleable chip for switching map data layers (parking, charging).
class _LayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _LayerChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassContainer(
      onTap: onTap,
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: active ? cs.primary.withValues(alpha: 0.9) : null,
      borderColor: active ? cs.primary : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: active ? cs.onPrimary : cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? cs.onPrimary : cs.onSurfaceVariant)),
      ]),
    );
  }
}

/// Floating button to toggle route creation mode with clear text label.
class _RouteCreationButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _RouteCreationButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.error : cs.primary;
    
    return GlassContainer(
      onTap: onTap,
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.close : Icons.add_road,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Cancel' : 'Create Route',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Instruction pill shown during route creation.
class _RouteInstructionPill extends StatelessWidget {
  final int step;

  const _RouteInstructionPill({required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GlassContainer(
        borderRadius: AppTheme.radiusLg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: cs.primaryContainer.withValues(alpha: 0.9),
        child: Text(
          step == 1 ? 'Tap start location' : 'Tap destination',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
        ),
      ),
    );
  }
}
