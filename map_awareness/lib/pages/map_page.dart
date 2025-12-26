import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/warning_item.dart';

/// Map page with route visualization and draggable info sheet
class MapPage extends StatefulWidget {
  final List<LatLng>? routePoints;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final List<LatLng>? roadworkPoints;
  final List<List<RoutingWidgetData>>? roadworks;
  final double? radiusKm;     // Optional radius circle
  final List<WarningItem>? warnings; // Optional warnings to display

  const MapPage({
    super.key,
    this.routePoints,
    this.startPoint,
    this.endPoint,
    this.roadworkPoints,
    this.roadworks,
    this.radiusKm,
    this.warnings,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _defaultCenter = LatLng(51.1657, 10.4515);
  static const _defaultZoom = 6.0;

  /// Whether we're in radius mode (showing location warnings vs route)
  bool get _isRadiusMode => widget.radiusKm != null && widget.startPoint != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final hasRoute = widget.routePoints != null && widget.routePoints!.isNotEmpty;
    final hasInfo = hasRoute || _isRadiusMode || (widget.roadworks != null && widget.roadworks!.any((l) => l.isNotEmpty));

    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const subdomains = ['a', 'b', 'c'];

    return Stack(
      children: [
        // Base map
        FlutterMap(
          options: MapOptions(
            initialCenter: _isRadiusMode ? widget.startPoint! : (hasRoute ? _calculateCenter() : _defaultCenter),
            initialZoom: _isRadiusMode ? _calculateZoomForRadius() : (hasRoute ? _calculateZoom() : _defaultZoom),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: subdomains,
              userAgentPackageName: 'com.map_awareness.app',
              tileProvider: NetworkTileProvider(),
            ),
            // Radius circle layer
            if (_isRadiusMode)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.startPoint!,
                    radius: widget.radiusKm! * 1000, // km to meters
                    useRadiusInMeter: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderColor: theme.colorScheme.primary,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),
            if (hasRoute)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints!,
                    color: theme.colorScheme.primary,
                    strokeWidth: 5.0,
                    borderColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    borderStrokeWidth: 1.0, 
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            MarkerLayer(markers: _buildMarkers(context)),
          ],
        ),
        // Draggable info sheet
        if (hasInfo)
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            snap: true,
            snapSizes: const [0.1, 0.3, 0.6],
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), 
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), 
                        borderRadius: BorderRadius.circular(2)
                      ),
                    ),
                  ),
                  Expanded(child: _isRadiusMode ? _buildWarningsContent(context, scrollController) : _buildInfoContent(context, scrollController)),
                ],
              ),
            ),
          ),
        // Empty state hint (only when no route and not radius mode)
        if (!hasRoute && !_isRadiusMode)
          Positioned(
            top: 16, left: 16, right: 16,
            child: Card(
              elevation: 2,
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calculate a route to see it here',
                        style: theme.textTheme.bodyMedium,
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Calculates appropriate zoom level based on radius
  double _calculateZoomForRadius() {
    final r = widget.radiusKm ?? 20;
    if (r > 80) return 7.0;
    if (r > 40) return 8.0;
    if (r > 20) return 9.0;
    if (r > 10) return 10.0;
    return 11.0;
  }

  /// Builds the warnings info sheet content
  Widget _buildWarningsContent(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    final warnings = widget.warnings ?? [];
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (warnings.isNotEmpty)
          Text(
            'Swipe up to see details',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Text(
            'No active warnings in this area',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        const SizedBox(height: 12),
        ...warnings.map((w) => Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: Icon(_getWarningIcon(w), color: _getSeverityColor(w.severity), size: 24),
            title: Text(w.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${w.source} • ${w.severity.label}'),
            trailing: w.isActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer, 
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      'ACTIVE', 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: theme.colorScheme.onErrorContainer
                      )
                    ),
                  )
                : null,
          ),
        )),
      ],
    );
  }

  IconData _getWarningIcon(WarningItem w) {
    switch (w.category) {
      case WarningCategory.weather: return Icons.wb_cloudy_outlined;
      case WarningCategory.flood: return Icons.water_drop_outlined;
      case WarningCategory.fire: return Icons.local_fire_department_outlined;
      case WarningCategory.health: return Icons.health_and_safety_outlined;
      case WarningCategory.civil: return Icons.campaign_outlined;
      case WarningCategory.environment: return Icons.local_florist_outlined;
      case WarningCategory.other: return Icons.info_outline;
    }
  }

  Color _getSeverityColor(WarningSeverity s) {
    switch (s) {
      case WarningSeverity.minor: return Colors.blue; 
      case WarningSeverity.moderate: return Colors.orange;
      case WarningSeverity.severe: return Colors.deepOrange;
      case WarningSeverity.extreme: return Colors.red;
    }
  }

  Widget _buildInfoContent(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    if (widget.roadworks == null || widget.roadworks!.every((l) => l.isEmpty)) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.routePoints != null) 
            Text('${widget.roadworkPoints?.length ?? 0} roadwork locations shown', style: theme.textTheme.bodyMedium),
        ],
      );
    }

    final all = [...widget.roadworks![0], ...widget.roadworks![1], ...widget.roadworks![2]];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          '${widget.roadworks![0].length} ongoing • ${widget.roadworks![1].length} short-term • ${widget.roadworks![2].length} future',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ...all.map((rw) => Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.construction, color: theme.colorScheme.tertiary, size: 20),
            title: Text(rw.title, style: const TextStyle(fontSize: 13)),
            subtitle: rw.infoSummary.isNotEmpty ? Text(rw.infoSummary, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis) : null,
          ),
        )),
      ],
    );
  }


  LatLng _calculateCenter() {
    if (widget.routePoints == null || widget.routePoints!.isEmpty) return _defaultCenter;
    double lat = 0, lng = 0;
    for (final p in widget.routePoints!) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / widget.routePoints!.length, lng / widget.routePoints!.length);
  }

  double _calculateZoom() {
    if (widget.routePoints == null || widget.routePoints!.length < 2) return _defaultZoom;
    double minLat = widget.routePoints!.first.latitude, maxLat = minLat, minLng = widget.routePoints!.first.longitude, maxLng = minLng;
    for (final p in widget.routePoints!) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final maxDiff = (maxLat - minLat) > (maxLng - minLng) ? (maxLat - minLat) : (maxLng - minLng);
    if (maxDiff > 5) return 5.0;
    if (maxDiff > 2) return 6.0;
    if (maxDiff > 1) return 7.0;
    if (maxDiff > 0.5) return 8.0;
    return 9.0;
  }

  /// Gets all roadwork data flattened for matching with points
  List<RoutingWidgetData> get _allRoadworks {
    if (widget.roadworks == null) return [];
    return [...widget.roadworks![0], ...widget.roadworks![1], ...widget.roadworks![2]];
  }

  /// Find roadwork data matching a point (by proximity)
  RoutingWidgetData? _findRoadworkForPoint(LatLng point) {
    for (final rw in _allRoadworks) {
      if (rw.latitude == null || rw.longitude == null) continue;
      // Check if roadwork is at this location (within ~1m tolerance)
      if ((rw.latitude! - point.latitude).abs() < 0.0001 &&
          (rw.longitude! - point.longitude).abs() < 0.0001) {
        return rw;
      }
    }
    return null;
  }

  void _showRoadworkInfo(BuildContext context, RoutingWidgetData rw) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.construction, color: theme.colorScheme.tertiary, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(rw.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 12),
            if (rw.subtitle.isNotEmpty) Text(rw.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (rw.infoSummary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                  rw.infoSummary, 
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500
                  )
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(rw.typeLabel), 
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                ),
                const SizedBox(width: 8),
                if (rw.isBlocked) 
                  Chip(
                    avatar: const Icon(Icons.block, size: 16, color: Colors.white),
                    label: const Text('Blocked', style: TextStyle(color: Colors.white)), 
                    backgroundColor: theme.colorScheme.error
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final theme = Theme.of(context);
    final markers = <Marker>[];
    if (widget.startPoint != null) {
      markers.add(Marker(point: widget.startPoint!, width: 40, height: 40, child: const Icon(Icons.trip_origin, color: Colors.green, size: 32)));
    }
    if (widget.endPoint != null) {
      markers.add(Marker(point: widget.endPoint!, width: 40, height: 40, child: const Icon(Icons.flag, color: Colors.red, size: 32)));
    }
    if (widget.roadworkPoints != null) {
      for (final p in widget.roadworkPoints!) {
        final rw = _findRoadworkForPoint(p);
        markers.add(Marker(
          point: p,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: rw != null ? () => _showRoadworkInfo(context, rw) : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
                ],
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
              ),
              child: Icon(Icons.construction, color: theme.colorScheme.tertiary, size: 20),
            ),
          ),
        ));
      }
    }
    return markers;
  }
}
