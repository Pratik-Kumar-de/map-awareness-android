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
import 'package:map_awareness/widgets/buttons/gradient_button.dart';
import 'package:map_awareness/widgets/buttons/secondary_button.dart';


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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Adapts map to provider changes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupListeners());
  }

  /// Configures Riverpod listeners to reactively adjust map camera when route or location state changes.
  void _setupListeners() {
    // Fits map to content.
    ref.listenManual(routeProvider.select((s) => s.polyline), (_, polyline) {
      if (_mapReady && polyline.isNotEmpty) {
        _fitToRoute(polyline);
      }
    });
    
    ref.listenManual(warningProvider.select((s) => s.center), (_, center) {
      final hasRoute = ref.read(routeProvider).hasRoute;
      if (_mapReady && center != null && !hasRoute) {
        final radius = ref.read(warningProvider).radiusKm;
        _fitToRadius(center, radius);
      }
    });
  }

  /// Callback executed when the map has finished initializing.
  void _onMapReady() {
    _mapReady = true;
    final routeState = ref.read(routeProvider);
    final warningState = ref.read(warningProvider);
    
    // Fits map initially.
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
    final routeState = ref.watch(routeProvider);
    final warningState = ref.watch(warningProvider);
    final cs = Theme.of(context).colorScheme;

    final hasRoute = routeState.hasRoute;
    final isRadiusMode = warningState.hasLocation && !hasRoute;
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
                   Haptics.select();
                   
                  // Dismisses active popup.
                   if (mounted && _activePopupKey != null && Navigator.of(context).canPop()) {
                     Navigator.of(context).pop();
                     _activePopupKey = null;
                   } else {
                    // Shows point selection.
                     _showPointSelectionSheet(point);
                   }
                 },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.map_awareness.app',
                retinaMode: MediaQuery.devicePixelRatioOf(context) > 1.0,
              ),
              if (isRadiusMode && center != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: center,
                    radius: warningState.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: cs.primary.withValues(alpha: 0.15),
                    borderColor: cs.primary,
                    borderStrokeWidth: 2.5,
                  ),
                ]),
              
              // Alternative Routes (Greyed out)
              if (hasRoute && routeState.alternatives.isNotEmpty)
                PolylineLayer(polylines: [
                  for (final alt in routeState.alternatives)
                    Polyline(
                      points: alt.coordinates,
                      color: cs.onSurface.withValues(alpha: 0.3),
                      strokeWidth: 4,
                      borderColor: Colors.white.withValues(alpha: 0.4),
                      borderStrokeWidth: 1,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                ]),

              if (hasRoute)
                PolylineLayer(polylines: [
                  Polyline(
                    points: routeState.polyline,
                    color: cs.primary,
                    strokeWidth: 5,
                    borderColor: cs.onSurface.withValues(alpha: 0.6),
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

          // No-route banner.
          if (!hasRoute && !isRadiusMode)
            Positioned(
              top: AppTheme.spacingMd,
              left: AppTheme.spacingMd,
              right: AppTheme.spacingMd,
              child: GlassContainer(
                color: cs.surface.withValues(alpha: 0.85),
                borderColor: cs.outline.withValues(alpha: 0.2),
                child: Row(children: [
                  Icon(Icons.info_outline, color: cs.primary, size: 20),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Calculate a route or search a location to view data',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)),
                    ),
                  ),
                ]),
              ),
            ),
            
          // Layer toggles.
          if (hasRoute)
            Positioned(
              top: AppTheme.spacingMd,
              right: AppTheme.spacingMd,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _LayerChip(
                  label: 'Parking',
                  icon: Icons.local_parking,
                  active: routeState.showParking,
                  onTap: () => ref.read(routeProvider.notifier).toggleParking(),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _LayerChip(
                  label: 'EV Charging',
                  icon: Icons.ev_station,
                  active: routeState.showCharging,
                  onTap: () => ref.read(routeProvider.notifier).toggleCharging(),
                ),
              ]),
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

    // Route markers.
    if (hasRoute && routeState.polyline.isNotEmpty) {
      markers.add(_marker(routeState.polyline.first, const MapMarker.small(icon: Icons.circle, color: AppTheme.success)));
      markers.add(_marker(routeState.polyline.last, const MapMarker.small(icon: Icons.flag_rounded, color: AppTheme.error)));
    }

    // Radius marker.
    if (isRadiusMode && warningState.center != null) {
      markers.add(_marker(warningState.center!, const MapMarker.small(icon: Icons.my_location, color: AppTheme.primary)));
    }

    // Charging stations.
    if (routeState.showCharging) {
      markers.addAll(_entityMarkers(
        items: routeState.chargingStations,
        id: (i) => 'cs_${i.identifier}',
        location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (_) => Icons.ev_station,
        color: (_) => AppTheme.success.withValues(alpha: 0.85),
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
        color: (_) => AppTheme.info.withValues(alpha: 0.8),
        sheet: _parkingSheet,
        size: 22,
      ));
    }

    // Roadworks.
    if (routeState.roadworks.isNotEmpty) {
      markers.addAll(_entityMarkers(
        items: routeState.roadworks.expand((l) => l),
        id: (i) => 'rw_${i.identifier}',
        location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (i) => i.isBlocked ? Icons.block : Icons.construction,
        color: (i) => (i.isBlocked ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.85),
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
    color: AppTheme.success,
    title: cs.title,
    subtitle: cs.subtitle,
    description: cs.descriptionText,
  );

  /// Builds a details sheet for a parking area.
  Widget _parkingSheet(ParkingDto p) => MapDetailsSheet(
    icon: Icons.local_parking,
    color: AppTheme.info,
    title: p.title,
    subtitle: p.subtitle,
    description: p.descriptionText,
    additionalChips: p.isLorryParking ? [
      Chip(
        avatar: const Icon(Icons.local_shipping, size: 16, color: AppTheme.info),
        label: const Text('Lorry parking'),
        backgroundColor: AppTheme.info.withValues(alpha: 0.1),
        side: BorderSide.none,
      ),
    ] : null,
  );

  /// Builds a details sheet for a roadwork event.
  Widget _roadworkSheet(RoadworkDto rw) {
    final c = rw.isBlocked ? AppTheme.error : AppTheme.warning;
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

  void _showPointSelectionSheet(LatLng point) async {
    Haptics.light();
    
    // Awaits geocoding result.
    String? address;
    try {
      address = await GeocodingService.getPlaceName(point.latitude, point.longitude);
    } catch (_) {}
    
    address ??= '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';

    if (!mounted) return;

    _dismissAndShow('loc_${point.hashCode}', _LocationActionSheet(address: address, point: point));
  }
}

/// Component for selecting start or destination for a specific map point.
class _LocationActionSheet extends ConsumerWidget {
  final String address;
  final LatLng point;
  
  const _LocationActionSheet({required this.address, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Location', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(address, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Start',
                  icon: Icons.trip_origin,
                  onPressed: () {
                    Haptics.medium();
                    ref.read(routeInputProvider.notifier).setStart(address);
                    Navigator.pop(context);
                    ToastService.success(context, 'Start point set');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: 'Destination',
                  icon: Icons.flag_rounded,
                  onPressed: () {
                    Haptics.medium();
                    ref.read(routeInputProvider.notifier).setEnd(address);
                    Navigator.pop(context);
                    ToastService.success(context, 'Destination set');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 10,
      blur: 6,
      color: Colors.white.withValues(alpha: 0.85),
      borderColor: Colors.black.withValues(alpha: 0.08),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

/// Simple vertical divider for control buttons.
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 1, color: Colors.black.withValues(alpha: 0.08));
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
    return GlassContainer(
      onTap: onTap,
      borderRadius: 20,
      blur: 6,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: active ? AppTheme.primary.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.85),
      borderColor: active ? AppTheme.primary : Colors.black.withValues(alpha: 0.1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.textSecondary)),
      ]),
    );
  }
}
