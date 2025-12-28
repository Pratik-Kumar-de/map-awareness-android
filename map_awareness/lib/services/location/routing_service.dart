import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/services/location/geocoding_service.dart';
import 'package:map_awareness/services/data/traffic_service.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/dto/dto.dart';


/// Result object containing autobahn segments, decoded polyline points, and alternative routes.
class RouteResult {
  final List<AutobahnData> autobahnList;
  final List<PointLatLng> polylinePoints;
  final List<RouteAlternative> alternatives;

  RouteResult({
    required this.autobahnList,
    required this.polylinePoints,
    this.alternatives = const [],
  });
}


/// Service for calculating routes and extracting autobahn segments.
class RoutingService {
  RoutingService._();

  /// Calculates route between two points, decodes the polyline, and identifies autobahn segments.
  static Future<RouteResult> getRouteWithPolyline(String start, String end) async {
    try {
      final res = await DioClient.instance.get(
        '${GeocodingService.baseUrl}/route',
        queryParameters: {
          'point': [start, end],
          'details': ['street_name', 'street_ref'],
          'profile': 'car',
          'locale': 'de',
          'calc_points': 'true',
          'alternative_route.max_paths': 3, // Max 3 alternatives
          'key': GeocodingService.apiKey,
        },
        options: DioClient.longCache(),
      );

      final paths = res.data['paths'] as List;
      final mainPath = paths[0];
      
      final polyline = PolylinePoints.decodePolyline(mainPath['points']);
      final autobahnNames = await _getAutobahnList();
      final autobahns = <AutobahnData>[];

      for (final ref in mainPath['details']['street_ref']) {
        if (ref[2] != null) {
          final name = (ref[2] as String).replaceAll(' ', '');
          if (autobahnNames.contains(name)) {
            final startPoint = polyline[ref[0]];
            final endPoint = polyline[ref[1]];
            autobahns.add(AutobahnData(
              name: name,
              startLat: startPoint.latitude,
              startLng: startPoint.longitude,
              endLat: endPoint.latitude,
              endLng: endPoint.longitude,
            ));
          }
        }
      }

      // Parses alternative routes.
      final alternatives = paths.skip(1).map((path) => RouteAlternative.fromJson(path)).toList();

      return RouteResult(
        autobahnList: autobahns,
        polylinePoints: polyline,
        alternatives: alternatives,
      );
    } on DioException {
      return RouteResult(autobahnList: [], polylinePoints: []);
    }
  }


  /// Fetches the list of available autobahns from the traffic API.
  static Future<Set<String>> _getAutobahnList() async {
    try {
      final res = await DioClient.instance.get(TrafficService.baseUrl, options: DioClient.longCache());
      return Set<String>.from(res.data['roads'] ?? []);
    } on DioException {
      return {};
    }
  }
}
