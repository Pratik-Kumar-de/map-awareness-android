import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// Data model for an alternative route option returned by GraphHopper.
class RouteAlternative {
  final double distance; // meters
  final int time; // milliseconds
  final List<double> bbox; // [minLon, minLat, maxLon, maxLat]
  final String points; // Encoded polyline

  RouteAlternative({
    required this.distance,
    required this.time,
    required this.bbox,
    required this.points,
  });

  factory RouteAlternative.fromJson(Map<String, dynamic> json) {
    return RouteAlternative(
      distance: (json['distance'] as num).toDouble(),
      time: json['time'] as int,
      bbox: (json['bbox'] as List).map((e) => (e as num).toDouble()).toList(),
      points: json['points'] as String,
    );
  }

  /// Decodes the encoded polyline string into a list of LatLng points.
  List<LatLng> get coordinates {
    final polylinePoints = PolylinePoints.decodePolyline(points);
    return polylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  /// Converts distance in meters to a readable kilometers string.
  String get distanceFormatted {
    final km = distance / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Converts time in milliseconds to a readable duration string (e.g. 1h 30m).
  String get durationFormatted {
    final minutes = (time / 1000 / 60).round();
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
  }
}
