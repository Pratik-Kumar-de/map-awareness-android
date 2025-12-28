
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/utils/string_utils.dart';

class GeocodingResult {
  final LatLng point;
  final String displayName;

  GeocodingResult({required this.point, required this.displayName});
  String get coordinates => '${point.latitude},${point.longitude}';
}

/// Centralized geocoding operations
class GeocodingService {
  static const apiKey = '95c5067c-b1d5-461f-823a-8ae69a6f6997';
  static const baseUrl = 'https://graphhopper.com/api/1';

  GeocodingService._();

  /// Convert address to coordinates, handles both plain addresses and lat,lng formats
  static Future<String?> toCoords(String input) async {
    if (input.isCoordinates) return input.normalizeCoords;
    final results = await search(input, limit: 1);
    return results.isNotEmpty ? results.first.coordinates : null;
  }

  /// Resolve input to human-readable name (reverse geocodes if coords)
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

  /// Search locations by query, returns geocoding results
  static Future<List<GeocodingResult>> search(String query, {int limit = 5}) async {
    try {
      final res = await DioClient.instance.get(
        '${GeocodingService.baseUrl}/geocode',
        queryParameters: {'q': query, 'locale': 'en', 'limit': limit, 'key': GeocodingService.apiKey},
        options: DioClient.shortCache(),
      );
      final hits = (res.data['hits'] as List?) ?? [];
      return hits.map((h) => GeocodingResult(
        point: LatLng((h['point']['lat'] as num).toDouble(), (h['point']['lng'] as num).toDouble()),
        displayName: h['name'] ?? h['city'] ?? query,
      )).toList();
    } catch (_) {
      return [];
    }
  }

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
      return null;
    }
  }
}
