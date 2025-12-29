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
      DioClient.safeGetList(
        '$baseUrl$name/services/roadworks', 
        listKey: 'roadworks', 
        fromJson: RoadworkDto.fromJson,
        options: DioClient.shortCache(),
      );

  /// Fetches electric charging stations from the API for a specific autobahn.
  static Future<List<ChargingStationDto>> getChargingStations(String name) => 
      DioClient.safeGetList(
        '$baseUrl$name/services/electric_charging_station', 
        listKey: 'electric_charging_station', 
        fromJson: ChargingStationDto.fromJson,
        options: DioClient.shortCache(),
      );

  /// Fetches parking areas from the API for a specific autobahn.
  static Future<List<ParkingDto>> getParkingAreas(String name) => 
      DioClient.safeGetList(
        '$baseUrl$name/services/parking_lorry', 
        listKey: 'parking_lorry', 
        fromJson: ParkingDto.fromJson,
        options: DioClient.shortCache(),
      );

  static Future<List<List<RoadworkDto>>> fetchRoadworksForSegments(List<AutobahnData> segments) async {
    final items = await _fetchValidItems(segments, getRoadworks);
    final ongoing = <RoadworkDto>[], shortTerm = <RoadworkDto>[], future = <RoadworkDto>[];
    
    for (final rw in items) {
      if (rw.isShortTerm) {
        shortTerm.add(rw);
      } else if (rw.isFuture) {
        future.add(rw);
      } else {
        ongoing.add(rw);
      }
    }

    return [ongoing, shortTerm, future];
  }

  static Future<List<ChargingStationDto>> fetchChargingForSegments(List<AutobahnData> segments) =>
      _fetchValidItems(segments, getChargingStations);

  static Future<List<ParkingDto>> fetchParkingForSegments(List<AutobahnData> segments) =>
      _fetchValidItems(segments, getParkingAreas);

  static Future<List<T>> _fetchValidItems<T extends AutobahnItemDto>(
    List<AutobahnData> segments,
    Future<List<T>> Function(String) fetcher,
  ) async {
    final groups = _groupByAutobahn(segments);
    final validItems = <T>[];
    final seen = <String>{};

    final allFetched = await Future.wait(groups.keys.map(fetcher));
    
    int i = 0;
    for (final groupSegments in groups.values) {
      for (final item in allFetched[i++]) {
        if (!seen.add(item.identifier)) continue;
        if (_matchesAnySegment(item.latitude, item.longitude, groupSegments, nullMatches: T == RoadworkDto)) {
          validItems.add(item);
        }
      }
    }
    return validItems;
  }

  static Map<String, List<AutobahnData>> _groupByAutobahn(List<AutobahnData> s) => groupBy(s, (s) => s.name);

  static bool _matchesAnySegment(double? lat, double? lng, List<AutobahnData> segments, {bool nullMatches = false}) {
    if (lat == null || lng == null) return nullMatches;
    for (final s in segments) {
      if (lat >= min(s.startLat, s.endLat) - 0.02 && lat <= max(s.startLat, s.endLat) + 0.02 &&
          lng >= min(s.startLng, s.endLng) - 0.02 && lng <= max(s.startLng, s.endLng) + 0.02) {
        return true;
      }
    }
    return false;
  }
}
