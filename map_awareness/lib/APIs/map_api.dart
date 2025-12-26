import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map_awareness/services/cache_service.dart';

String mapURLStart = "https://graphhopper.com/api/1/route?point=";
String point2 = "&point=";
String mapURLend = "&details=street_name&details=street_ref&profile=car&locale=de&calc_points=true&key=95c5067c-b1d5-461f-823a-8ae69a6f6997";

String autobahnList1 = "https://verkehr.autobahn.de/";
String autobahnList2 = "/autobahn/";

/// Geocoding result with coordinates and display name
class GeocodingResult {
  final double lat;
  final double lng;
  final String displayName;
  
  GeocodingResult({required this.lat, required this.lng, required this.displayName});
  
  /// Returns coordinates as "lat,lng" string for routing API
  String get coordinates => '$lat,$lng';
}

/// Convert address/street name to coordinates using GraphHopper Geocoding API
Future<List<GeocodingResult>> geocode(String query, {int limit = 5}) async {
  final url = 'https://graphhopper.com/api/1/geocode?q=${Uri.encodeComponent(query)}&locale=de&limit=$limit&key=95c5067c-b1d5-461f-823a-8ae69a6f6997';
  final res = await http.get(Uri.parse(url));
  
  if (res.statusCode != 200) return [];
  
  final data = jsonDecode(res.body);
  final hits = data['hits'] as List? ?? [];
  
  return hits.map((h) => GeocodingResult(
    lat: (h['point']['lat'] as num).toDouble(),
    lng: (h['point']['lng'] as num).toDouble(),
    displayName: h['name'] ?? h['city'] ?? query,
  )).toList();
}

/// String name, PointLatLng start, PointLatLng end
class AutobahnClass{
  final String name;
  final PointLatLng start;
  final PointLatLng end;

  AutobahnClass({
    required this.name,
    required this.start,
    required this.end
  });
}

/// Combined result from routing: autobahn segments + polyline for map display
class RouteResult {
  final List<AutobahnClass> autobahnList;
  final List<PointLatLng> polylinePoints;

  RouteResult({required this.autobahnList, required this.polylinePoints});
}

///gets all street names in a car route between 2 coordinate points
Future<List<AutobahnClass>> routing(String startingPoint, String endPoint) async {
  final result = await routingWithPolyline(startingPoint, endPoint);
  return result.autobahnList;
}

/// Returns route with polyline points for map display
Future<RouteResult> routingWithPolyline(String startingPoint, String endPoint) async {
  List<AutobahnClass> autobahnList = [];

  final cachedData = await CacheService.getCachedRouteResponse(startingPoint, endPoint);
  final Map<String, dynamic> data;

  if (cachedData != null) {
    data = cachedData;
  } else {
    String mapURL = mapURLStart + startingPoint + point2 + endPoint + mapURLend;
    final res = await http.get(Uri.parse(mapURL));
    if (res.statusCode == 200) {
      data = jsonDecode(res.body);
      await CacheService.cacheRouteResponse(startingPoint, endPoint, data);
    } else {
      return RouteResult(autobahnList: [], polylinePoints: []);
    }
  }

  // Decode polyline for map display
  List<PointLatLng> polylinePoints = PolylinePoints.decodePolyline(data["paths"][0]["points"]);
  
  // Extract autobahn segments
  Map<String, dynamic> autobahnNames = await isAutobahn();
  for (int i = 0; i < data["paths"][0]["details"]["street_ref"].length; i++) {
    if (data["paths"][0]["details"]["street_ref"][i][2] != null) {
      String streetName = data["paths"][0]["details"]["street_ref"][i][2];
      String spacelessName = streetName.replaceAll(' ', "");
      if (autobahnNames["roads"].contains(spacelessName)) {
        autobahnList.add(AutobahnClass(
          name: spacelessName,
          start: polylinePoints[data["paths"][0]["details"]["street_ref"][i][0]],
          end: polylinePoints[data["paths"][0]["details"]["street_ref"][i][1]],
        ));
      }
    }
  }

  return RouteResult(autobahnList: autobahnList, polylinePoints: polylinePoints);
}

///returns a list of every Autobahn (cached for 24 hours)
Future<Map<String, dynamic>> isAutobahn() async {
  // Check cache first
  final cachedData = await CacheService.getCachedAutobahnList();
  if (cachedData != null) {
    return cachedData;
  }

  String roadname = "o";
  String mapURL = autobahnList1 + roadname + autobahnList2;

  final res = await http.get(Uri.parse(mapURL));
  
  Map<String, dynamic> data = {};

  if (res.statusCode == 200) {
    data = jsonDecode(res.body);
    await CacheService.cacheAutobahnList(data);
    return data;
  }

  return data;
}

/// Reverse geocode coordinates to get a city/address name
Future<String?> reverseGeocode(double lat, double lng) async {
  final url = 'https://graphhopper.com/api/1/geocode?point=$lat,$lng&reverse=true&locale=de&limit=1&key=95c5067c-b1d5-461f-823a-8ae69a6f6997';
  try {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    
    final data = jsonDecode(res.body);
    final hits = data['hits'] as List? ?? [];
    if (hits.isEmpty) return null;

    final hit = hits.first;
    // Try to get the most relevant name: city, town, village, or name
    final name = hit['city'] ?? hit['town'] ?? hit['village'] ?? hit['name'] ?? hit['street'];
    return name;
  } catch (e) {
    return null;
  }
}
