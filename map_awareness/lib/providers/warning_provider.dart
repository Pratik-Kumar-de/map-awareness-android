import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/services.dart';
import 'package:map_awareness/utils/string_utils.dart';

/// Immutable state object managing warning data, location context, and environmental metrics.
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
  final WeatherDto? currentWeather;
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
    this.currentWeather,
    this.isLoading = false,
    this.isSummaryLoading = false,
  });

  /// Creates a copy of the state with optional updated fields.
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
    WeatherDto? currentWeather,
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
      currentWeather: currentWeather ?? this.currentWeather,
      isLoading: isLoading ?? this.isLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
    );
  }

  bool get hasLocation => lat != null && lng != null;
  LatLng? get center => hasLocation ? LatLng(lat!, lng!) : null;
}

/// Manages location-based warning search, aggregation of DWD/NINA/OpenMeteo data, and AI summaries.
class WarningNotifier extends StateNotifier<WarningState> {
  WarningNotifier() : super(const WarningState());

  /// Updates the search radius in kilometers.
  void setRadius(double km) => state = state.copyWith(radiusKm: km);

  /// Geocodes the query string and updates state with the first result's location.
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

  /// Manually sets the focus location and triggers a data fetch.
  Future<void> setLocation(double lat, double lng, String text) async {
    state = state.copyWith(lat: lat, lng: lng, locationText: text, isLoading: true);
    await _fetchWarnings();
  }

  /// Fetches unified warnings, air quality, flood data, and weather in parallel.
  Future<void> _fetchWarnings() async {
    final city = state.locationText?.cityName ?? '';
    final lat = state.lat;
    final lng = state.lng;

    // Parallel API calls.
    final results = await Future.wait([
      WarningService.getUnifiedWarningsForCities([city]),
      if (lat != null && lng != null) EnvironmentService.getAirQuality(lat, lng) else Future.value(null),
      if (lat != null && lng != null) EnvironmentService.getFloodData(lat, lng) else Future.value(null),
      if (lat != null && lng != null) EnvironmentService.getWeather(lat, lng) else Future.value(null),
    ]);

    final allWarnings = results[0] as List<WarningItem>;
    final rawAq = results.length > 1 ? results[1] as OpenMeteoAirQualityDto? : null;
    final rawFlood = results.length > 2 ? results[2] as OpenMeteoFloodDto? : null;
    final weather = results.length > 3 ? results[3] as WeatherDto? : null;

    // Builds info items.
    final allInfoItems = <WarningItem>[];
    if (rawAq != null) {
      final item = WarningItem.fromOpenMeteoAirQuality(rawAq);
      if (item != null) allInfoItems.add(item);
    }
    if (rawFlood != null) {
      final item = WarningItem.fromOpenMeteoFlood(rawFlood);
      if (item != null) allInfoItems.add(item);
    }

    state = state.copyWith(
      warnings: allWarnings,
      infoItems: allInfoItems,
      rawAirQuality: rawAq,
      rawFloodData: rawFlood,
      currentWeather: weather,
      isLoading: false,
      isSummaryLoading: true,
    );

    _generateSummary(allWarnings);
  }

  /// Generates AI location summary using aggregated warning/environmental data.
  Future<void> _generateSummary(List<WarningItem> warnings) async {
    try {
      final summary = await GeminiService.generateLocationSummary(
        state.locationText?.cityName ?? '',
        warnings,
        radiusKm: state.radiusKm,
        airQuality: state.rawAirQuality,
        floodData: state.rawFloodData,
        currentWeather: state.currentWeather,
      );
      state = state.copyWith(aiSummary: summary, isSummaryLoading: false);
    } catch (_) {
      state = state.copyWith(isSummaryLoading: false);
    }
  }

  /// Refreshes the AI summary based on current warnings.
  Future<void> refreshSummary() async {
    state = state.copyWith(isSummaryLoading: true);
    await _generateSummary(state.warnings);
  }

  /// Reloads all warning and environmental data for the current location.
  Future<void> refresh() async {
    if (!state.hasLocation) return;
    state = state.copyWith(isLoading: true);
    await _fetchWarnings();
  }
}

final warningProvider = StateNotifierProvider<WarningNotifier, WarningState>((ref) => WarningNotifier());
