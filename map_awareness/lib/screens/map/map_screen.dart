import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/warning_item.dart';

/// Map screen with route/radius visualization
class MapScreen extends StatelessWidget {
  final List<LatLng>? routePoints;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final List<LatLng>? roadworkPoints;
  final List<List<RoutingWidgetData>>? roadworks;
  final double? radiusKm;
  final List<WarningItem>? warnings;

  const MapScreen({
    super.key,
    this.routePoints,
    this.startPoint,
    this.endPoint,
    this.roadworkPoints,
    this.roadworks,
    this.radiusKm,
    this.warnings,
  });

  static const _defaultCenter = LatLng(51.1657, 10.4515);
  static const _defaultZoom = 6.0;

  bool get _isRadiusMode => radiusKm != null && startPoint != null;
  bool get _hasRoute => routePoints != null && routePoints!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _isRadiusMode ? startPoint! : (_hasRoute ? _center : _defaultCenter),
            initialZoom: _isRadiusMode ? _zoomForRadius : (_hasRoute ? _zoomForRoute : _defaultZoom),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.map_awareness.app',
            ),
            // Radius circle
            if (_isRadiusMode)
              CircleLayer(circles: [
                CircleMarker(
                  point: startPoint!,
                  radius: radiusKm! * 1000,
                  useRadiusInMeter: true,
                  color: cs.primary.withValues(alpha: 0.15),
                  borderColor: cs.primary,
                  borderStrokeWidth: 2.5,
                ),
              ]),
            // Route line
            if (_hasRoute)
              PolylineLayer(polylines: [
                Polyline(
                  points: routePoints!,
                  color: cs.primary,
                  strokeWidth: 5,
                  borderColor: cs.onSurface.withValues(alpha: 0.6),
                  borderStrokeWidth: 1,
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                ),
              ]),
            MarkerLayer(markers: _buildMarkers(context)),
          ],
        ),

        // Info sheet
        if (_hasRoute || _isRadiusMode)
          DraggableScrollableSheet(
            initialChildSize: 0.12,
            minChildSize: 0.08,
            maxChildSize: 0.5,
            snap: true,
            snapSizes: const [0.08, 0.25, 0.5],
            builder: (ctx, controller) => Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(child: _buildSheetContent(context, controller)),
                ],
              ),
            ),
          ),

        // No route hint
        if (!_hasRoute && !_isRadiusMode)
          Positioned(
            top: 16, left: 16, right: 16,
            child: Card(
              elevation: 2,
              color: cs.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Calculate a route or search a location to see it here')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  LatLng get _center {
    if (routePoints == null || routePoints!.isEmpty) return _defaultCenter;
    double lat = 0, lng = 0;
    for (final p in routePoints!) { lat += p.latitude; lng += p.longitude; }
    return LatLng(lat / routePoints!.length, lng / routePoints!.length);
  }

  double get _zoomForRoute {
    if (routePoints == null || routePoints!.length < 2) return _defaultZoom;
    double minLat = routePoints!.first.latitude, maxLat = minLat;
    double minLng = routePoints!.first.longitude, maxLng = minLng;
    for (final p in routePoints!) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final diff = (maxLat - minLat) > (maxLng - minLng) ? (maxLat - minLat) : (maxLng - minLng);
    if (diff > 5) return 5.0;
    if (diff > 2) return 6.0;
    if (diff > 1) return 7.0;
    if (diff > 0.5) return 8.0;
    return 9.0;
  }

  double get _zoomForRadius {
    final r = radiusKm ?? 20;
    if (r > 80) return 7.0;
    if (r > 40) return 8.0;
    if (r > 20) return 9.0;
    if (r > 10) return 10.0;
    return 11.0;
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>[];
    final cs = Theme.of(context).colorScheme;

    if (startPoint != null) {
      markers.add(Marker(point: startPoint!, width: 40, height: 40, child: const Icon(Icons.trip_origin, color: Colors.green, size: 32)));
    }
    if (endPoint != null) {
      markers.add(Marker(point: endPoint!, width: 40, height: 40, child: const Icon(Icons.flag, color: Colors.red, size: 32)));
    }
    if (roadworkPoints != null) {
      for (final p in roadworkPoints!) {
        markers.add(Marker(
          point: p, width: 32, height: 32,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
            ),
            child: Icon(Icons.construction, color: cs.tertiary, size: 18),
          ),
        ));
      }
    }
    return markers;
  }

  Widget _buildSheetContent(BuildContext context, ScrollController controller) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isRadiusMode) {
      final w = warnings ?? [];
      return ListView(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Text(w.isEmpty ? 'No warnings in this area' : '${w.length} warnings', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...w.map((wi) => Card(
            elevation: 0,
            color: cs.surfaceContainer,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Icon(_iconForCategory(wi.category), color: _colorForSeverity(wi.severity)),
              title: Text(wi.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${wi.source} • ${wi.severity.label}'),
            ),
          )),
        ],
      );
    }

    // Route info
    final all = roadworks != null ? [...roadworks![0], ...roadworks![1], ...roadworks![2]] : <RoutingWidgetData>[];
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text('${roadworkPoints?.length ?? 0} roadwork locations', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...all.map((rw) => Card(
          elevation: 0,
          color: cs.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.construction, color: cs.tertiary, size: 20),
            title: Text(rw.title, style: const TextStyle(fontSize: 13)),
            subtitle: rw.infoSummary.isNotEmpty ? Text(rw.infoSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)) : null,
          ),
        )),
      ],
    );
  }

  IconData _iconForCategory(WarningCategory c) {
    switch (c) {
      case WarningCategory.weather: return Icons.wb_cloudy_outlined;
      case WarningCategory.flood: return Icons.water_drop_outlined;
      case WarningCategory.fire: return Icons.local_fire_department_outlined;
      case WarningCategory.health: return Icons.health_and_safety_outlined;
      case WarningCategory.civil: return Icons.campaign_outlined;
      case WarningCategory.environment: return Icons.local_florist_outlined;
      case WarningCategory.other: return Icons.info_outline;
    }
  }

  Color _colorForSeverity(WarningSeverity s) {
    switch (s) {
      case WarningSeverity.minor: return Colors.blue;
      case WarningSeverity.moderate: return Colors.orange;
      case WarningSeverity.severe: return Colors.deepOrange;
      case WarningSeverity.extreme: return Colors.red;
    }
  }
}
