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
  final RouteAlternative mainRoute;

  RouteResult({
    required this.autobahnList,
    required this.polylinePoints,
    required this.mainRoute,
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
          'locale': 'en',
          'calc_points': 'true',
          'alternative_route.max_paths': 3, // Max 3 alternatives
          'key': GeocodingService.apiKey,
        },
        options: DioClient.longCache(),
      );

      final paths = res.data['paths'] as List;
      final autobahnNames = await _getAutobahnList();
      
      // Parses all paths (main + alternatives) to extract segments.
      final parsedPaths = _parseRoutePaths(paths, autobahnNames);

      final main = parsedPaths[0];
      
      // Creates alternatives list.
      final alternatives = parsedPaths.skip(1).map((p) => RouteAlternative.fromJson(
        p['data'], 
        segments: p['autobahns'] as List<AutobahnData>,
      )).toList();

      final mainRoute = RouteAlternative.fromJson(
        main['data'], 
        segments: main['autobahns'] as List<AutobahnData>,
      );

      return RouteResult(
        autobahnList: main['autobahns'] as List<AutobahnData>,
        polylinePoints: main['polyline'] as List<PointLatLng>,
        alternatives: alternatives,
        mainRoute: mainRoute,
      );
    } on DioException {
      return RouteResult(
        autobahnList: [], 
        polylinePoints: [],
        mainRoute: RouteAlternative(
          distance: 0, 
          time: 0, 
          bbox: [], 
          points: '',
        ),
      );
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
  /// Parses raw route paths to extract decoded polylines and autobahn segments.
  static List<Map<String, dynamic>> _parseRoutePaths(List paths, Set<String> autobahnNames) {
    final parsedPaths = <Map<String, dynamic>>[];

    for (final path in paths) {
      final polyline = PolylinePoints.decodePolyline(path['points']);
      final autobahns = <AutobahnData>[];

      final details = path['details'] as Map<String, dynamic>?;
      if (details != null && details['street_ref'] != null) {
        for (final ref in details['street_ref']) {
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
      }
      
      parsedPaths.add({
        'polyline': polyline,
        'autobahns': autobahns,
        'data': path,
      });
    }
    return parsedPaths;
  }
}
