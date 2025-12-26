
// RoutingWidgetData uses PointLatLng?
// Line 95 in routing.dart: bool _isRoadworkInSegment(AutobahnRoadworks rw, PointLatLng segmentStart, PointLatLng segmentEnd)
// But routing.dart imports flutter_polyline_points. 
// RoutingWidgetData class (lines 9-54) does NOT use PointLatLng. It uses double? latitude, longitude.
// So no special imports needed except maybe standard dart libs if used?
// It seems simple class.

class RoutingWidgetData {
  final String title;
  final String subtitle;
  final String time;
  final String displayType;
  final String? length;
  final String? speedLimit;
  final String? maxWidth;
  final bool isBlocked;
  // Location for map display (center of roadwork extent)
  final double? latitude;
  final double? longitude;

  RoutingWidgetData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.displayType,
    this.length,
    this.speedLimit,
    this.maxWidth,
    this.isBlocked = false,
    this.latitude,
    this.longitude,
  });

  String get typeLabel {
    switch (displayType) {
      case 'SHORT_TERM_ROADWORKS':
        return 'Short-term';
      case 'ROADWORKS':
        return 'Roadworks';
      default:
        return displayType.isEmpty ? 'Unknown' : displayType;
    }
  }
  
  /// Summary line: combines length, speed, width
  String get infoSummary {
    final parts = <String>[];
    if (length case final l?) parts.add(l);
    if (speedLimit case final s?) parts.add('Max. $s');
    if (maxWidth case final w?) parts.add('Width: $w');
    return parts.isEmpty ? '' : parts.join(' | ');
  }
}
