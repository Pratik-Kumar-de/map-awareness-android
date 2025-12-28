import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/services/location/geocoding_service.dart';
import 'package:map_awareness/services/data/traffic_service.dart';
import 'package:map_awareness/models/saved_route.dart';

class RouteResult {
  final List<AutobahnData> autobahnList;
  final List<PointLatLng> polylinePoints;

  RouteResult({required this.autobahnList, required this.polylinePoints});
}

class RoutingService {
  RoutingService._();

  /// Calculate route with polyline and autobahn segments
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
          'key': GeocodingService.apiKey,
        },
        options: DioClient.longCache(),
      );

      final polyline = PolylinePoints.decodePolyline(res.data['paths'][0]['points']);
      final autobahnNames = await _getAutobahnList();
      final autobahns = <AutobahnData>[];

      for (final ref in res.data['paths'][0]['details']['street_ref']) {
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
      return RouteResult(autobahnList: autobahns, polylinePoints: polyline);
    } on DioException {
      return RouteResult(autobahnList: [], polylinePoints: []);
    }
  }

  /// Get list of all autobahns
  static Future<Set<String>> _getAutobahnList() async {
    try {
      final res = await DioClient.instance.get(TrafficService.baseUrl, options: DioClient.longCache());
      return Set<String>.from(res.data['roads'] ?? []);
    } on DioException {
      return {};
    }
  }
}
