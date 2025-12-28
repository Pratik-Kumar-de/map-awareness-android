import 'dart:math' as math;

/// Safe bool parser for JSON
bool safeBool(dynamic v) => v == true || v == 'true';

/// Simple bounding box for coordinates
class Bounds {
  final double minLat, maxLat, minLng, maxLng;
  const Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  factory Bounds.fromPoints(double lat1, double lng1, double lat2, double lng2) {
    return Bounds(
      math.min(lat1, lat2),
      math.max(lat1, lat2),
      math.min(lng1, lng2),
      math.max(lng1, lng2),
    );
  }

  bool contains(double lat, double lng, {double buffer = 0}) =>
      lat >= minLat - buffer && lat <= maxLat + buffer &&
      lng >= minLng - buffer && lng <= maxLng + buffer;
}

/// Finds value in list by prefix match
String? findByPrefix(List<String>? lines, String prefix) {
  if (lines == null) return null;
  for (final line in lines) {
    if (line.contains(prefix)) return line.replaceAll('$prefix:', '').trim();
  }
  return null;
}
