
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/utils/string_utils.dart';

/// Result object from a geocoding operation holding coordinates and a display name.
class GeocodingResult {
  final LatLng point;
  final String displayName;

  GeocodingResult({required this.point, required this.displayName});
  /// Formats the geographic point as a comma-separated latitude/longitude string.
  String get coordinates => '${point.latitude},${point.longitude}';
}

/// Service handling forward and reverse geocoding via GraphHopper API.
class GeocodingService {
  static const apiKey = '95c5067c-b1d5-461f-823a-8ae69a6f6997';
  static const baseUrl = 'https://graphhopper.com/api/1';

  GeocodingService._();

  /// Converts input string to a coordinate string if it's already coordinates, or fetches them via search.
  static Future<String?> toCoords(String input) async {
    if (input.isCoordinates) return input.normalizeCoords;
    final results = await search(input, limit: 1);
    return results.isNotEmpty ? results.first.coordinates : null;
  }

  /// Resolves a coordinate string to a human-readable place name if possible.
  static Future<String> resolveName(String input) async {
    if (input.isCoordinates) {
      final parts = input.split(',');
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        return await getPlaceName(lat, lng) ?? input;
      }
    }
    return input;
  }

  /// Performs a geocoding search query against the API.
  static Future<List<GeocodingResult>> search(String query, {int limit = 5}) async {
    try {
      final res = await DioClient.instance.get(
        '${GeocodingService.baseUrl}/geocode',
        queryParameters: {'q': query, 'locale': 'en', 'limit': limit, 'key': GeocodingService.apiKey},
        options: DioClient.shortCache(),
      );
      final hits = (res.data['hits'] as List?) ?? [];
      return hits.map((h) {
        final name = h['name'] ?? h['city'] ?? query;
        final city = h['city'] as String?;
        final country = h['country'] as String?;
        final parts = <String>[name];
        if (city != null && city != name) parts.add(city);
        if (country != null) parts.add(country);
        return GeocodingResult(
          point: LatLng((h['point']['lat'] as num).toDouble(), (h['point']['lng'] as num).toDouble()),
          displayName: parts.join(', '),
        );
      }).toList();
    } catch (_) {
      // Graceful degradation: return empty on API failure.
      return [];
    }
  }

  /// Performs reverse geocoding to find the name of a place at the given coordinates.
  static Future<String?> getPlaceName(double lat, double lng) async {
    try {
      final res = await DioClient.instance.get(
        '${GeocodingService.baseUrl}/geocode',
        queryParameters: {'point': '$lat,$lng', 'reverse': 'true', 'locale': 'en', 'limit': 1, 'key': GeocodingService.apiKey},
        options: DioClient.shortCache(),
      );
      final hits = (res.data['hits'] as List?) ?? [];
      if (hits.isEmpty) return null;
      final hit = hits.first;
      return hit['city'] ?? hit['town'] ?? hit['village'] ?? hit['name'] ?? hit['street'];
    } catch (_) {
      // Graceful degradation: return null on reverse geocode failure.
      return null;
    }
  }
}
