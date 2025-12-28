import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/models/saved_route.dart';
import 'package:map_awareness/models/saved_location.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/string_utils.dart';

// --- Navigation State ---
final currentTabProvider = StateProvider<int>((ref) => 0);

// --- Route State ---
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
  final bool isLoading;
  final bool isSummaryLoading;
  final bool showParking; // optional layer toggle
  final bool showCharging; // optional layer toggle

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
      isLoading: isLoading ?? this.isLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      showParking: showParking ?? this.showParking,
      showCharging: showCharging ?? this.showCharging,
    );
  }

  bool get hasRoute => polyline.isNotEmpty;
}

class RouteNotifier extends StateNotifier<RouteState> {
  RouteNotifier() : super(const RouteState());

  Future<bool> calculate(String start, String end) async {
    state = state.copyWith(isLoading: true, aiSummary: null);

    final startCoords = await GeocodingService.toCoords(start);
    final endCoords = await GeocodingService.toCoords(end);
    if (startCoords == null || endCoords == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final routeResult = await RoutingService.getRouteWithPolyline(startCoords, endCoords);
    final roadworks = await TrafficService.fetchRoadworksForSegments(routeResult.autobahnList);
    final charging = await TrafficService.fetchChargingForSegments(routeResult.autobahnList);
    final parking = await TrafficService.fetchParkingForSegments(routeResult.autobahnList);

    // Fetch warnings for route
    final warnings = await WarningService.getUnifiedWarningsForCities([start.cityName, end.cityName]);

    final startName = await GeocodingService.resolveName(start);
    final endName = await GeocodingService.resolveName(end);

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
      isLoading: false,
      isSummaryLoading: true,
    );

    _generateSummary(roadworks, warnings, startName, endName);
    return true;
  }

  Future<void> _generateSummary(List<List<RoadworkDto>> roadworks, List<WarningItem> warnings, String start, String end) async {
    try {
      final allRw = [...roadworks[0], ...roadworks[1], ...roadworks[2]];
      final summary = await GeminiService.generateRouteSummary(allRw, warnings, start, end);
      state = state.copyWith(aiSummary: summary, isSummaryLoading: false);
    } catch (_) {
      state = state.copyWith(isSummaryLoading: false);
    }
  }

  Future<void> refreshSummary() async {
    if (state.startName == null || state.endName == null) return;
    state = state.copyWith(isSummaryLoading: true);
    await _generateSummary(state.roadworks, state.warnings, state.startName!, state.endName!);
  }

  void clear() {
    state = const RouteState();
  }

  // toggle optional layers
  void toggleParking() => state = state.copyWith(showParking: !state.showParking);
  void toggleCharging() => state = state.copyWith(showCharging: !state.showCharging);
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) => RouteNotifier());

// --- Saved Routes ---
final savedRoutesProvider = FutureProvider<List<SavedRoute>>((ref) => StorageService.loadRoutes());

// --- Warning State ---
class WarningState {
  final List<WarningItem> warnings;
  final List<WarningItem> infoItems;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? locationText;
  final String? aiSummary;
  final OpenMeteoAirQualityDto? rawAirQuality;
  final OpenMeteoFloodDto? rawFloodData;
  final bool isLoading;
  final bool isSummaryLoading;

  const WarningState({
    this.warnings = const [],
    this.infoItems = const [],
    this.lat,
    this.lng,
    this.radiusKm = 20,
    this.locationText,
    this.aiSummary,
    this.rawAirQuality,
    this.rawFloodData,
    this.isLoading = false,
    this.isSummaryLoading = false,
  });

  WarningState copyWith({
    List<WarningItem>? warnings,
    List<WarningItem>? infoItems,
    double? lat,
    double? lng,
    double? radiusKm,
    String? locationText,
    String? aiSummary,
    OpenMeteoAirQualityDto? rawAirQuality,
    OpenMeteoFloodDto? rawFloodData,
    bool? isLoading,
    bool? isSummaryLoading,
  }) {
    return WarningState(
      warnings: warnings ?? this.warnings,
      infoItems: infoItems ?? this.infoItems,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      locationText: locationText ?? this.locationText,
      aiSummary: aiSummary ?? this.aiSummary,
      rawAirQuality: rawAirQuality ?? this.rawAirQuality,
      rawFloodData: rawFloodData ?? this.rawFloodData,
      isLoading: isLoading ?? this.isLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
    );
  }

  bool get hasLocation => lat != null && lng != null;
  LatLng? get center => hasLocation ? LatLng(lat!, lng!) : null;
}

class WarningNotifier extends StateNotifier<WarningState> {
  WarningNotifier() : super(const WarningState());

  void setRadius(double km) => state = state.copyWith(radiusKm: km);

  Future<bool> search(String query) async {
    state = state.copyWith(isLoading: true);
    final results = await GeocodingService.search(query, limit: 1);
    if (results.isEmpty) {
      state = state.copyWith(isLoading: false);
      return false;
    }
    state = state.copyWith(
      lat: results.first.point.latitude,
      lng: results.first.point.longitude,
      locationText: results.first.displayName,
    );
    await _fetchWarnings();
    return true;
  }

  Future<void> setLocation(double lat, double lng, String text) async {
    state = state.copyWith(lat: lat, lng: lng, locationText: text, isLoading: true);
    await _fetchWarnings();
  }

  Future<void> _fetchWarnings() async {
    final city = state.locationText?.cityName ?? '';
    final allWarnings = await WarningService.getUnifiedWarningsForCities([city]);
    final allInfoItems = <WarningItem>[];

    OpenMeteoAirQualityDto? rawAq;
    OpenMeteoFloodDto? rawFlood;
    if (state.lat != null && state.lng != null) {
      try {
        final aq = await EnvironmentService.getAirQuality(state.lat!, state.lng!);
        if (aq != null) {
          rawAq = aq;
          final item = WarningItem.fromOpenMeteoAirQuality(aq);
          if (item != null) allInfoItems.add(item);
        }
      } catch (_) {}
      try {
        final flood = await EnvironmentService.getFloodData(state.lat!, state.lng!);
        if (flood != null) {
          rawFlood = flood;
          final item = WarningItem.fromOpenMeteoFlood(flood);
          if (item != null) allInfoItems.add(item);
        }
      } catch (_) {}
    }

    state = state.copyWith(
      warnings: allWarnings,
      infoItems: allInfoItems,
      rawAirQuality: rawAq,
      rawFloodData: rawFlood,
      isLoading: false,
      isSummaryLoading: true,
    );

    _generateSummary(allWarnings);
  }

  Future<void> _generateSummary(List<WarningItem> warnings) async {
    try {
      final summary = await GeminiService.generateLocationSummary(
        state.locationText?.cityName ?? '',
        warnings,
        radiusKm: state.radiusKm,
        airQuality: state.rawAirQuality,
        floodData: state.rawFloodData,
      );
      state = state.copyWith(aiSummary: summary, isSummaryLoading: false);
    } catch (_) {
      state = state.copyWith(isSummaryLoading: false);
    }
  }

  Future<void> refreshSummary() async {
    state = state.copyWith(isSummaryLoading: true);
    await _generateSummary(state.warnings);
  }

  Future<void> refresh() async {
    if (!state.hasLocation) return;
    state = state.copyWith(isLoading: true);
    await _fetchWarnings();
  }
}

final warningProvider = StateNotifierProvider<WarningNotifier, WarningState>((ref) => WarningNotifier());

// --- Saved Locations ---
final savedLocationsProvider = FutureProvider<List<SavedLocation>>((ref) => StorageService.loadLocations());
