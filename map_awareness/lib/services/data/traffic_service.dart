import 'dart:math';
import 'package:collection/collection.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/saved_route.dart';


/// Service handling traffic data retrieval from autobahn.de API.
class TrafficService {
  static const baseUrl = 'https://verkehr.autobahn.de/o/autobahn/';
  TrafficService._();

  /// Fetches roadworks from the API for a specific autobahn.
  static Future<List<RoadworkDto>> getRoadworks(String name) => 
      _safeFetch('$baseUrl$name/services/roadworks', 'roadworks', RoadworkDto.fromJson);

  /// Fetches electric charging stations from the API for a specific autobahn.
  static Future<List<ChargingStationDto>> getChargingStations(String name) => 
      _safeFetch('$baseUrl$name/services/electric_charging_station', 'electric_charging_station', ChargingStationDto.fromJson);

  /// Fetches parking areas from the API for a specific autobahn.
  static Future<List<ParkingDto>> getParkingAreas(String name) => 
      _safeFetch('$baseUrl$name/services/parking_lorry', 'parking_lorry', ParkingDto.fromJson);

  /// Generic helper to fetch and parse list data from the API safely handling errors.
  static Future<List<T>> _safeFetch<T>(String url, String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final res = await DioClient.instance.get(url, options: DioClient.shortCache());
      return (res.data[key] as List? ?? []).map((e) => fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Iterates through segments, fetches roadworks, filters by bounds, and groups into ongoing/shortTerm/future.
  static Future<List<List<RoadworkDto>>> fetchRoadworksForSegments(List<AutobahnData> segments) async {
    final ongoing = <RoadworkDto>[], shortTerm = <RoadworkDto>[], future = <RoadworkDto>[];
    final seen = <String>{};

    for (final entry in _groupByAutobahn(segments).entries) {
      final allRw = await getRoadworks(entry.key);
      for (final rw in allRw) {
        if (seen.contains(rw.identifier)) continue;
        if (!_matchesAnySegment(rw.latitude, rw.longitude, entry.value, nullMatches: true)) continue;
        
        seen.add(rw.identifier);
        if (rw.isShortTerm) {
          shortTerm.add(rw);
        } else if (rw.isFuture) {
          future.add(rw);
        } else {
          ongoing.add(rw);
        }
      }
    }
    return [ongoing, shortTerm, future];
  }

  /// Fetches and filters charging stations for the given segments.
  static Future<List<ChargingStationDto>> fetchChargingForSegments(List<AutobahnData> segments) async {
    return _fetchFilteredItems(segments, getChargingStations, (s) => (s.latitude, s.longitude), (s) => s.identifier);
  }

  /// Fetches and filters parking areas for the given segments.
  static Future<List<ParkingDto>> fetchParkingForSegments(List<AutobahnData> segments) =>
      _fetchFilteredItems(segments, getParkingAreas, (p) => (p.latitude, p.longitude), (p) => p.identifier);

  /// Helper to filter fetched items based on their spatial presence within segments.
  static Future<List<T>> _fetchFilteredItems<T>(
    List<AutobahnData> segments,
    Future<List<T>> Function(String) fetcher,
    (double?, double?) Function(T) getCoords,
    String Function(T) getId,
  ) async {
    final result = <T>[];
    final seen = <String>{};

    for (final entry in _groupByAutobahn(segments).entries) {
      final items = await fetcher(entry.key);
      for (final item in items) {
        final id = getId(item);
        if (seen.contains(id)) continue;
        final (lat, lng) = getCoords(item);
        if (_matchesAnySegment(lat, lng, entry.value)) {
          seen.add(id);
          result.add(item);
        }
      }
    }
    return result;
  }

  /// Groups a list of segments by their autobahn name.
  static Map<String, List<AutobahnData>> _groupByAutobahn(List<AutobahnData> segments) =>
      groupBy(segments, (s) => s.name);

  /// Checks if a coordinate point lies within the buffered bounds of any segment in the list.
  static bool _matchesAnySegment(double? lat, double? lng, List<AutobahnData> segments, {bool nullMatches = false}) {
    if (lat == null || lng == null) return nullMatches;

    
    for (final seg in segments) {
      final minLat = min(seg.startLat, seg.endLat);
      final maxLat = max(seg.startLat, seg.endLat);
      final minLng = min(seg.startLng, seg.endLng);
      final maxLng = max(seg.startLng, seg.endLng);

      // Checks bounds with buffer.
      if (lat >= minLat - 0.02 && lat <= maxLat + 0.02 &&
          lng >= minLng - 0.02 && lng <= maxLng + 0.02) {
        return true;
      }
    }
    return false;
  }
}
