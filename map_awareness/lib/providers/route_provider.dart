import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/string_utils.dart';

/// Immutable state object holding route data including polyline, markers, and metadata.
class RouteState {
  final List<LatLng> polyline;
  final List<List<RoadworkDto>> roadworks;
  final List<AutobahnData> autobahns;
  final List<WarningItem> warnings;
  final List<ChargingStationDto> chargingStations;
  final List<ParkingDto> parkingAreas;
  final String? startName;
  final String? endName;
  final String? startCoords;
  final String? endCoords;
  final String? aiSummary;
  final WeatherDto? departureWeather;
  final WeatherDto? arrivalWeather;
  final List<RouteAlternative> alternatives;
  final bool isLoading;
  final bool isSummaryLoading;
  final bool showParking;
  final bool showCharging;

  const RouteState({
    this.polyline = const [],
    this.roadworks = const [],
    this.autobahns = const [],
    this.warnings = const [],
    this.chargingStations = const [],
    this.parkingAreas = const [],
    this.startName,
    this.endName,
    this.startCoords,
    this.endCoords,
    this.aiSummary,
    this.departureWeather,
    this.arrivalWeather,
    this.alternatives = const [],
    this.isLoading = false,
    this.isSummaryLoading = false,
    this.showParking = false,
    this.showCharging = false,
  });

  RouteState copyWith({
    List<LatLng>? polyline,
    List<List<RoadworkDto>>? roadworks,
    List<AutobahnData>? autobahns,
    List<WarningItem>? warnings,
    List<ChargingStationDto>? chargingStations,
    List<ParkingDto>? parkingAreas,
    String? startName,
    String? endName,
    String? startCoords,
    String? endCoords,
    String? aiSummary,
    WeatherDto? departureWeather,
    WeatherDto? arrivalWeather,
    List<RouteAlternative>? alternatives,
    bool? isLoading,
    bool? isSummaryLoading,
    bool? showParking,
    bool? showCharging,
  }) {
    return RouteState(
      polyline: polyline ?? this.polyline,
      roadworks: roadworks ?? this.roadworks,
      autobahns: autobahns ?? this.autobahns,
      warnings: warnings ?? this.warnings,
      chargingStations: chargingStations ?? this.chargingStations,
      parkingAreas: parkingAreas ?? this.parkingAreas,
      startName: startName ?? this.startName,
      endName: endName ?? this.endName,
      startCoords: startCoords ?? this.startCoords,
      endCoords: endCoords ?? this.endCoords,
      aiSummary: aiSummary ?? this.aiSummary,
      departureWeather: departureWeather ?? this.departureWeather,
      arrivalWeather: arrivalWeather ?? this.arrivalWeather,
      alternatives: alternatives ?? this.alternatives,
      isLoading: isLoading ?? this.isLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      showParking: showParking ?? this.showParking,
      showCharging: showCharging ?? this.showCharging,
    );
  }

  bool get hasRoute => polyline.isNotEmpty;
}

/// Manages route calculations, fetching data from multiple services (GraphHopper, Traffic, Weather).
class RouteNotifier extends StateNotifier<RouteState> {
  RouteNotifier() : super(const RouteState());

  /// Calculates route and fetches all associated data (roadworks, warnings, weather) converting address strings to coordinates.
  Future<bool> calculate(String start, String end) async {
    state = state.copyWith(isLoading: true, aiSummary: null);

    // Geocode start and end in parallel.
    final coords = await Future.wait([
      GeocodingService.toCoords(start),
      GeocodingService.toCoords(end),
    ]);
    final startCoords = coords[0];
    final endCoords = coords[1];
    if (startCoords == null || endCoords == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final routeResult = await RoutingService.getRouteWithPolyline(startCoords, endCoords);

    // Parses coordinates for weather.
    final startLatLng = startCoords.split(',');
    final endLatLng = endCoords.split(',');
    final startLat = double.parse(startLatLng[0]);
    final startLng = double.parse(startLatLng[1]);
    final endLat = double.parse(endLatLng[0]);
    final endLng = double.parse(endLatLng[1]);

    // Estimates arrival time.
    final totalDistance = routeResult.polylinePoints.fold(0.0, (sum, point) => sum);
    final estimatedHours = totalDistance / 100000;
    final arrivalTime = clock.now().add(Duration(minutes: (estimatedHours * 60).round()));

    // Parallel fetch: traffic data, warnings, names, weather.
    final results = await Future.wait([
      TrafficService.fetchRoadworksForSegments(routeResult.autobahnList),
      TrafficService.fetchChargingForSegments(routeResult.autobahnList),
      TrafficService.fetchParkingForSegments(routeResult.autobahnList),
      WarningService.getUnifiedWarningsForCities([start.cityName, end.cityName]),
      GeocodingService.resolveName(start),
      GeocodingService.resolveName(end),
      EnvironmentService.getWeather(startLat, startLng),
      EnvironmentService.getWeather(endLat, endLng, forecastTime: arrivalTime),
    ]);

    final roadworks = results[0] as List<List<RoadworkDto>>;
    final charging = results[1] as List<ChargingStationDto>;
    final parking = results[2] as List<ParkingDto>;
    final warnings = results[3] as List<WarningItem>;
    final startName = results[4] as String;
    final endName = results[5] as String;
    final departureWeather = results[6] as WeatherDto?;
    final arrivalWeather = results[7] as WeatherDto?;

    state = state.copyWith(
      polyline: routeResult.polylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      autobahns: routeResult.autobahnList,
      roadworks: roadworks,
      chargingStations: charging,
      parkingAreas: parking,
      warnings: warnings..sort(),
      startName: startName,
      endName: endName,
      startCoords: startCoords,
      endCoords: endCoords,
      departureWeather: departureWeather,
      arrivalWeather: arrivalWeather,
      alternatives: routeResult.alternatives,
      isLoading: false,
      isSummaryLoading: true,
    );

    _generateSummary(roadworks, warnings, startName, endName, departureWeather, arrivalWeather);
    return true;
  }


  /// Triggers AI summary generation for the route using roadworks and weather context.
  Future<void> _generateSummary(
    List<List<RoadworkDto>> roadworks,
    List<WarningItem> warnings,
    String start,
    String end,
    WeatherDto? departureWeather,
    WeatherDto? arrivalWeather,
  ) async {
    try {
      final allRw = [...roadworks[0], ...roadworks[1], ...roadworks[2]];
      final summary = await GeminiService.generateRouteSummary(
        allRw,
        warnings,
        start,
        end,
        departureWeather: departureWeather,
        arrivalWeather: arrivalWeather,
      );
      state = state.copyWith(aiSummary: summary, isSummaryLoading: false);
    } catch (_) {
      state = state.copyWith(isSummaryLoading: false);
    }
  }


  /// Refreshes the AI summary based on current state.
  Future<void> refreshSummary() async {
    if (state.startName == null || state.endName == null) return;
    state = state.copyWith(isSummaryLoading: true);
    await _generateSummary(
      state.roadworks,
      state.warnings,
      state.startName!,
      state.endName!,
      state.departureWeather,
      state.arrivalWeather,
    );
  }


  void clear() => state = const RouteState();

  void toggleParking() => state = state.copyWith(showParking: !state.showParking);
  void toggleCharging() => state = state.copyWith(showCharging: !state.showCharging);
  
  /// Recalculates route if start/end coordinates exist.
  Future<void> refresh(String start, String end) async {
    if (start.isEmpty || end.isEmpty) return;
    await calculate(start, end);
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) => RouteNotifier());
