import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/map_details_sheet.dart';
import 'package:map_awareness/widgets/common/glass_container.dart';
import 'package:map_awareness/widgets/common/map_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  static const _defaultCenter = LatLng(51.1657, 10.4515);
  static const _defaultZoom = 6.0;
  // track active popup to dismiss before opening another
  String? _activePopupKey;

  @override
  bool get wantKeepAlive => true;

  // dismiss current popup if any, then set new key
  void _dismissAndShow(String key, void Function() show) {
    if (_activePopupKey != null) Navigator.of(context).pop();
    _activePopupKey = key;
    show();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final routeState = ref.watch(routeProvider);
    final warningState = ref.watch(warningProvider);
    final cs = Theme.of(context).colorScheme;

    // Determine display mode
    final isRadiusMode = warningState.hasLocation && !routeState.hasRoute;
    final hasRoute = routeState.hasRoute;
    final routePoints = routeState.polyline;
    final center = isRadiusMode ? warningState.center : (hasRoute ? routePoints.firstOrNull : null);
    final radiusKm = warningState.radiusKm;

    // SizedBox.expand ensures map gets proper constraints on first render
    return SizedBox.expand(child: Container(color: cs.surface, child: Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center ?? _defaultCenter,
            initialZoom: isRadiusMode ? _zoomForRadius(radiusKm) : _defaultZoom,
            onMapReady: hasRoute ? () => _fitToContent(routePoints) : null,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            onTap: (tapPos, point) {
              if (_activePopupKey != null) Navigator.of(context).pop();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.map_awareness.app',
              tileProvider: NetworkTileProvider(),
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
            ),

            if (isRadiusMode && center != null)
              CircleLayer(circles: [
                CircleMarker(
                  point: center,
                  radius: radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: cs.primary.withValues(alpha: 0.15),
                  borderColor: cs.primary,
                  borderStrokeWidth: 2.5,
                ),
              ]),
            if (hasRoute)
              PolylineLayer(polylines: [
                Polyline(
                  points: routePoints,
                  color: cs.primary,
                  strokeWidth: 5,
                  borderColor: cs.onSurface.withValues(alpha: 0.6),
                  borderStrokeWidth: 1,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                ),
              ]),
            MarkerLayer(markers: _buildMarkers(context, routeState, warningState, hasRoute, isRadiusMode)),
          ],
        ),

        Positioned(
          right: 16, bottom: 100,
          child: _MapControls(
            onZoomIn: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            onZoomOut: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            onRecenter: (hasRoute || isRadiusMode) ? () => _fitToContent(hasRoute ? routePoints : null, isRadiusMode ? center : null, isRadiusMode ? radiusKm : null) : null,
          ),
        ),

        if (!hasRoute && !isRadiusMode)
          Positioned(
            top: 16, left: 16, right: 16,
            child: GlassContainer(
              color: cs.surface.withValues(alpha: 0.7),
              borderColor: cs.outline.withValues(alpha: 0.2),
              child: Row(children: [
                Icon(Icons.info_outline, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Calculate a route or search a location', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)))),
              ]),
            ),
          ),

        // optional layer toggles when route active
        if (hasRoute)
          Positioned(
            top: 16, right: 16,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _LayerChip(label: 'Parking', icon: Icons.local_parking, active: routeState.showParking, onTap: () => ref.read(routeProvider.notifier).toggleParking()),
              const SizedBox(width: 8),
              _LayerChip(label: 'EV Charging', icon: Icons.ev_station, active: routeState.showCharging, onTap: () => ref.read(routeProvider.notifier).toggleCharging()),
            ]),
          ),
      ],
    )));
  }

  double _zoomForRadius(double r) {
    if (r > 80) return 7.0;
    if (r > 40) return 8.0;
    if (r > 20) return 9.0;
    if (r > 10) return 10.0;
    return 11.0;
  }

  void _fitToContent([List<LatLng>? routePoints, LatLng? center, double? radiusKm]) {
    if (center != null && radiusKm != null) {
      _mapController.move(center, _zoomForRadius(radiusKm));
    } else if (routePoints != null && routePoints.isNotEmpty) {
      _mapController.fitCamera(CameraFit.coordinates(coordinates: routePoints, padding: const EdgeInsets.all(50)));
    }
  }

  List<Marker> _buildMarkers(BuildContext context, RouteState routeState, WarningState warningState, bool hasRoute, bool isRadiusMode) {
    final markers = <Marker>[];

    // Start/End markers for route
    if (hasRoute && routeState.polyline.isNotEmpty) {
      markers.add(_buildMarkerWithType(routeState.polyline.first, const MapMarker.small(icon: Icons.circle, color: AppTheme.success)));
      markers.add(_buildMarkerWithType(routeState.polyline.last, const MapMarker.small(icon: Icons.flag_rounded, color: AppTheme.error)));
    }

    // Center marker for radius mode
    if (isRadiusMode && warningState.center != null) {
      markers.add(_buildMarkerWithType(warningState.center!, const MapMarker.small(icon: Icons.my_location, color: AppTheme.primary)));
    }

    // Charging stations
    if (routeState.showCharging) {
      markers.addAll(_buildEntityMarkers(
        items: routeState.chargingStations,
        id: (i) => 'cs_${i.identifier}',
        location: (i) => i.coordinate != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (_) => Icons.ev_station,
        color: (_) => AppTheme.success.withValues(alpha: 0.85),
        sheetBuilder: _buildChargingSheet,
        size: 24,
      ));
    }

    // Parking areas
    if (routeState.showParking) {
      markers.addAll(_buildEntityMarkers(
        items: routeState.parkingAreas,
        id: (i) => 'pk_${i.identifier}',
        location: (i) => i.coordinate != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (_) => Icons.local_parking,
        color: (_) => AppTheme.info.withValues(alpha: 0.8),
        sheetBuilder: _buildParkingSheet,
        size: 22,
      ));
    }

    // Roadworks
    if (routeState.roadworks.isNotEmpty) {
      markers.addAll(_buildEntityMarkers(
        items: routeState.roadworks.expand((l) => l),
        id: (i) => 'rw_${i.identifier}',
        location: (i) => i.coordinate != null ? LatLng(i.latitude!, i.longitude!) : null,
        icon: (i) => i.isBlocked ? Icons.block : Icons.construction,
        color: (i) => (i.isBlocked ? AppTheme.error : AppTheme.warning).withValues(alpha: 0.85),
        sheetBuilder: _buildRoadworkSheet,
      ));
    }

    // Warnings
    markers.addAll(_buildEntityMarkers(
      items: isRadiusMode ? warningState.warnings : routeState.warnings,
      id: (i) => 'wn_${i.title.hashCode}',
      location: (i) => i.latitude != null && i.longitude != null ? LatLng(i.latitude!, i.longitude!) : null,
      icon: (_) => Icons.warning_amber_rounded,
      color: (i) => i.severity.color.withValues(alpha: 0.85),
      sheetBuilder: _buildWarningSheet,
      size: 26,
    ));

    return markers;
  }

  // Generic helper for consistent marker creation
  Iterable<Marker> _buildEntityMarkers<T>({
    required Iterable<T> items,
    required String Function(T) id,
    required LatLng? Function(T) location,
    required IconData Function(T) icon,
    required Color Function(T) color,
    required Widget Function(T) sheetBuilder,
    double size = 28,
  }) {
    return items.map((item) {
      final loc = location(item);
      if (loc == null) return null;
      return Marker(
        point: loc, width: size, height: size,
        child: MapMarker(
          icon: icon(item),
          backgroundColor: color(item),
          onTap: () => _dismissAndShow(id(item), () => _showDetails(context, sheetBuilder(item))),
        ),
      );
    }).whereType<Marker>();
  }

  Marker _buildMarkerWithType(LatLng point, Widget child, {double width = 28, double height = 28}) => Marker(
    point: point, width: width, height: height, child: child,
  );

  Widget _buildChargingSheet(ChargingStationDto cs) {
    return MapDetailsSheet(
      icon: Icons.ev_station,
      color: AppTheme.success,
      title: cs.title,
      subtitle: cs.subtitle,
      description: cs.descriptionText,
    );
  }

  Widget _buildParkingSheet(ParkingDto p) {
    return MapDetailsSheet(
      icon: Icons.local_parking,
      color: AppTheme.info,
      title: p.title,
      subtitle: p.subtitle,
      description: p.descriptionText,
      additionalChips: p.isLorryParking ? [
        Chip(
          avatar: Icon(Icons.local_shipping, size: 16, color: AppTheme.info),
          label: const Text('Lorry parking'),
          backgroundColor: AppTheme.info.withValues(alpha: 0.1),
          side: BorderSide.none,
        )
      ] : null,
    );
  }

  Widget _buildRoadworkSheet(RoadworkDto rw) {
    final c = rw.isBlocked ? AppTheme.error : AppTheme.warning;
    return MapDetailsSheet(
      icon: rw.isBlocked ? Icons.block : Icons.construction,
      color: c,
      title: rw.title,
      subtitle: rw.subtitle,
      description: rw.descriptionText,
      additionalChips: [
        if (rw.isBlocked) Chip(avatar: Icon(Icons.block, size: 16, color: c), label: const Text('Road blocked'), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        Chip(avatar: Icon(Icons.access_time, size: 16, color: c), label: Text(rw.timeInfo), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        if (rw.length != null) Chip(label: Text(rw.length!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
        if (rw.speedLimit != null) Chip(avatar: Icon(Icons.speed, size: 16, color: c), label: Text(rw.speedLimit!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
      ],
    );
  }

  Widget _buildWarningSheet(WarningItem w) {
    return MapDetailsSheet(
      icon: Icons.warning_amber_rounded,
      color: w.severity.color,
      title: w.title,
      subtitle: '${w.severity.label} • ${w.source}',
      description: w.description,
      additionalChips: [
        Chip(avatar: Icon(Icons.schedule, size: 16, color: w.severity.color), label: Text(w.formattedTimeRange), backgroundColor: w.severity.color.withValues(alpha: 0.1), side: BorderSide.none),
      ],
    );
  }

  void _showDetails(BuildContext context, Widget sheet) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.01),
      builder: (_) => sheet,
    ).whenComplete(() => _activePopupKey = null);
  }
}

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
        Container(height: 1, color: Colors.black.withValues(alpha: 0.08)),
        _ControlButton(icon: Icons.remove, onTap: onZoomOut),
        if (onRecenter != null) ...[Container(height: 1, color: Colors.black.withValues(alpha: 0.08)), _ControlButton(icon: Icons.center_focus_strong, onTap: onRecenter!)],
      ]),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20, color: AppTheme.textSecondary)),
      ),
    );
  }
}

// toggle chip for optional map layers
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
