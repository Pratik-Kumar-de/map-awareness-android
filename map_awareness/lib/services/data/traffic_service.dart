import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/utils/helpers.dart';

class TrafficService {
  static const baseUrl = 'https://verkehr.autobahn.de/o/autobahn/';
  TrafficService._();

  /// Fetch roadworks for an autobahn
  static Future<List<RoadworkDto>> getRoadworks(String name) async {
    try {
      final res = await DioClient.instance.get('$baseUrl$name/services/roadworks', options: DioClient.shortCache());
      return (res.data['roadworks'] as List? ?? []).map((rw) => RoadworkDto.fromJson(rw)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch electric charging stations for an autobahn
  static Future<List<ChargingStationDto>> getChargingStations(String name) async {
    try {
      final res = await DioClient.instance.get('$baseUrl$name/services/electric_charging_station', options: DioClient.shortCache());
      return (res.data['electric_charging_station'] as List? ?? []).map((s) => ChargingStationDto.fromJson(s)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch parking/rest areas for an autobahn
  static Future<List<ParkingDto>> getParkingAreas(String name) async {
    try {
      final res = await DioClient.instance.get('$baseUrl$name/services/parking_lorry', options: DioClient.shortCache());
      return (res.data['parking_lorry'] as List? ?? []).map((p) => ParkingDto.fromJson(p)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch roadworks for given segments
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

  /// Fetch charging stations for given segments
  static Future<List<ChargingStationDto>> fetchChargingForSegments(List<AutobahnData> segments) async {
    return _fetchFilteredItems(segments, getChargingStations, (s) => (s.latitude, s.longitude), (s) => s.identifier);
  }

  /// Fetch parking areas for given segments
  static Future<List<ParkingDto>> fetchParkingForSegments(List<AutobahnData> segments) =>
      _fetchFilteredItems(segments, getParkingAreas, (p) => (p.latitude, p.longitude), (p) => p.identifier);

  // Generic method to filter items by segment bounds
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

  static Map<String, List<AutobahnData>> _groupByAutobahn(List<AutobahnData> segments) {
    final map = <String, List<AutobahnData>>{};
    for (final s in segments) {
      map.putIfAbsent(s.name, () => []).add(s);
    }
    return map;
  }

  static bool _matchesAnySegment(double? lat, double? lng, List<AutobahnData> segments, {bool nullMatches = false}) {
    if (lat == null || lng == null) return nullMatches;
    const buffer = 0.02;
    for (final seg in segments) {
      final bounds = Bounds.fromPoints(seg.startLat, seg.startLng, seg.endLat, seg.endLng);
      if (bounds.contains(lat, lng, buffer: buffer)) return true;
    }
    return false;
  }
}
