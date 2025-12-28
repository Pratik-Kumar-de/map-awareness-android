import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/utils/app_theme.dart';

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
    return SizedBox.expand(child: Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center ?? _defaultCenter,
            initialZoom: isRadiusMode ? _zoomForRadius(radiusKm) : _defaultZoom,
            onMapReady: hasRoute ? () => _fitToContent(routePoints) : null,
            onTap: (tapPos, point) {
              if (_activePopupKey != null) Navigator.of(context).pop();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.map_awareness.app',
              keepBuffer: 8,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Calculate a route or search a location', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)))),
                  ]),
                ),
              ),
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
    ));
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

    // Start/End markers for route - compact with subtle shadow
    if (hasRoute && routeState.polyline.isNotEmpty) {
      markers.add(_buildSmallMarker(routeState.polyline.first, Icons.circle, Colors.green[700]!));
      markers.add(_buildSmallMarker(routeState.polyline.last, Icons.flag_rounded, Colors.red[700]!));
    }

    // Center marker for radius mode
    if (isRadiusMode && warningState.center != null) {
      markers.add(_buildSmallMarker(warningState.center!, Icons.my_location, AppTheme.primary));
    }

    // charging station markers - only if enabled
    if (routeState.showCharging) {
      for (final cs in routeState.chargingStations) {
        if (cs.latitude == null || cs.longitude == null) continue;
        markers.add(Marker(
          point: LatLng(cs.latitude!, cs.longitude!),
          width: 24, height: 24,
          child: GestureDetector(
            onTap: () => _dismissAndShow('cs_${cs.identifier}', () => _showChargingPopup(context, cs)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[600]!.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.ev_station, color: Colors.white, size: 14),
            ),
          ),
        ));
      }
    }

    // parking markers - only if enabled
    if (routeState.showParking) {
      for (final p in routeState.parkingAreas) {
        if (p.latitude == null || p.longitude == null) continue;
        markers.add(Marker(
          point: LatLng(p.latitude!, p.longitude!),
          width: 22, height: 22,
          child: GestureDetector(
            onTap: () => _dismissAndShow('pk_${p.identifier}', () => _showParkingPopup(context, p)),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 12),
            ),
          ),
        ));
      }
    }

    // Roadwork markers - smaller, semi-transparent
    if (routeState.roadworks.isNotEmpty) {
      final allRoadworks = routeState.roadworks.expand((list) => list).toList();
      for (final rw in allRoadworks) {
        if (rw.latitude == null || rw.longitude == null) continue;
        final color = rw.isBlocked ? AppTheme.error : AppTheme.warning;
        markers.add(Marker(
          point: LatLng(rw.latitude!, rw.longitude!),
          width: 28, height: 28,
          child: GestureDetector(
            onTap: () => _dismissAndShow('rw_${rw.identifier}', () => _showRoadworkPopup(context, rw)),
            child: Container(
              decoration: BoxDecoration(color: color.withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(rw.isBlocked ? Icons.block : Icons.construction, color: Colors.white, size: 14),
            ),
          ),
        ));
      }
    }

    // Warning markers - smaller, semi-transparent
    final warnings = isRadiusMode ? warningState.warnings : routeState.warnings;
    for (final w in warnings) {
      if (w.latitude == null || w.longitude == null) continue;
      markers.add(Marker(
        point: LatLng(w.latitude!, w.longitude!),
        width: 26, height: 26,
        child: GestureDetector(
          onTap: () => _dismissAndShow('wn_${w.title.hashCode}', () => _showWarningPopup(context, w)),
          child: Container(
            decoration: BoxDecoration(color: w.severity.color.withValues(alpha: 0.85), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
          ),
        ),
      ));
    }

    return markers;
  }

  Marker _buildSmallMarker(LatLng point, IconData icon, Color color) => Marker(
    point: point, width: 28, height: 28,
    child: Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)]),
      child: Icon(icon, color: color, size: 18),
    ),
  );

  // standard bottom sheet for charging/parking/roadwork
  void _showChargingPopup(BuildContext context, ChargingStationDto cs) => _showInfoSheet(context,
    icon: Icons.ev_station, color: Colors.green, title: cs.title, subtitle: cs.subtitle, description: cs.descriptionText);

  void _showParkingPopup(BuildContext context, ParkingDto p) => _showInfoSheet(context,
    icon: Icons.local_parking, color: AppTheme.info, title: p.title, subtitle: p.subtitle, description: p.descriptionText,
    badge: p.isLorryParking ? 'Lorry parking' : null);

  void _showInfoSheet(BuildContext context, {required IconData icon, required Color color, required String title, String subtitle = '', String description = '', String? badge}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.2,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: ListView(controller: controller, padding: const EdgeInsets.all(20), children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))),
            if (badge != null) Padding(padding: const EdgeInsets.only(top: 12), child: Chip(avatar: Icon(Icons.local_shipping, size: 16, color: color), label: Text(badge), backgroundColor: color.withValues(alpha: 0.1), side: BorderSide.none)),
            if (description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5))),
          ]),
        ),
      ),
    ).whenComplete(() => _activePopupKey = null);
  }

  void _showRoadworkPopup(BuildContext context, RoadworkDto rw) {
    final c = rw.isBlocked ? Colors.red : AppTheme.warning;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.4, maxChildSize: 0.8, minChildSize: 0.2,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: ListView(controller: controller, padding: const EdgeInsets.all(20), children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(rw.isBlocked ? Icons.block : Icons.construction, color: c)),
              const SizedBox(width: 12),
              Expanded(child: Text(rw.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (rw.subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(rw.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))),
            if (rw.isBlocked) Padding(padding: const EdgeInsets.only(top: 12), child: Chip(avatar: const Icon(Icons.block, size: 16, color: Colors.red), label: const Text('Road blocked'), backgroundColor: Colors.red.withValues(alpha: 0.1), side: BorderSide.none)),
            Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(avatar: Icon(Icons.access_time, size: 16, color: c), label: Text(rw.timeInfo), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
              if (rw.length != null) Chip(label: Text(rw.length!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
              if (rw.speedLimit != null) Chip(avatar: Icon(Icons.speed, size: 16, color: c), label: Text(rw.speedLimit!), backgroundColor: c.withValues(alpha: 0.1), side: BorderSide.none),
            ])),
            if (rw.descriptionText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(rw.descriptionText, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5))),
          ]),
        ),
      ),
    ).whenComplete(() => _activePopupKey = null);
  }

  void _showWarningPopup(BuildContext context, WarningItem w) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.radiusLg),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: w.severity.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber, color: w.severity.color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(w.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: w.severity.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${w.severity.label} • ${w.source}', style: TextStyle(color: w.severity.color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            if (w.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(w.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary), maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(w.formattedTimeRange, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _ControlButton(icon: Icons.add, onTap: onZoomIn),
            Container(height: 1, color: Colors.black.withValues(alpha: 0.08)),
            _ControlButton(icon: Icons.remove, onTap: onZoomOut),
            if (onRecenter != null) ...[Container(height: 1, color: Colors.black.withValues(alpha: 0.08)), _ControlButton(icon: Icons.center_focus_strong, onTap: onRecenter!)],
          ]),
        ),
      ),
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
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppTheme.primary.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? AppTheme.primary : Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.textSecondary)),
            ]),
          ),
        ),
      ),
    );
  }
}
