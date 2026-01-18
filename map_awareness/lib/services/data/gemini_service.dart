import 'package:clock/clock.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/core/api_key_service.dart';

// Caches AI summaries (15m TTL).
final Map<String, _CachedSummary> _cache = {};

class _CachedSummary {
  final String text;
  final DateTime time;
  _CachedSummary(this.text) : time = clock.now();
  bool get isValid => clock.now().difference(time).inMinutes < 15;
}

/// Service for generating AI summaries using Google's Gemini model.
class GeminiService {
  GeminiService._();

  /// Removes expired entries from the local cache.
  static void _cleanupCache() => _cache.removeWhere((_, v) => !v.isValid);

  /// Generates a travel safety summary for a route using roadworks, warnings, and weather data.
  static Future<String> generateRouteSummary(
    List<RoadworkDto> roadworks,
    List<WarningItem> warnings,
    String start,
    String end, {
    WeatherDto? departureWeather,
    WeatherDto? arrivalWeather,
  }) async {
    _cleanupCache();
    final activeWarnings = warnings.where((w) => w.isActive).toList();
    final key = 'route:$start:$end:${roadworks.length}:${activeWarnings.length}';
    if (_cache[key]?.isValid == true) return _cache[key]!.text;

    final apiKey = await ApiKeyService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key required - please configure in Settings.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
      
      // Categorize roadworks.
      final blocked = roadworks.where((r) => r.isBlocked).length;
      final shortTerm = roadworks.where((r) => r.isShortTerm).length;
      final severeWarnings = activeWarnings.where((w) => w.severity.level >= 3).length;
      
      // Build weather summary.
      String weather = '';
      if (departureWeather != null) {
        weather += '\n- Start: ${departureWeather.icon} ${departureWeather.temperature?.toStringAsFixed(0)}°C${departureWeather.precipitation != null && departureWeather.precipitation! > 0 ? ', ${departureWeather.precipitation}mm rain' : ''}${departureWeather.windSpeed != null ? ', ${departureWeather.windSpeed!.toStringAsFixed(0)}km/h wind' : ''}';
      }
      if (arrivalWeather != null) {
        weather += '\n- End: ${arrivalWeather.icon} ${arrivalWeather.temperature?.toStringAsFixed(0)}°C${arrivalWeather.precipitation != null && arrivalWeather.precipitation! > 0 ? ', ${arrivalWeather.precipitation}mm rain' : ''}${arrivalWeather.windSpeed != null ? ', ${arrivalWeather.windSpeed!.toStringAsFixed(0)}km/h wind' : ''}';
      }
      
      final prompt = '''Brief English travel safety summary (max 4 sentences) for $start → $end.

Stats: ${roadworks.length} roadworks ($blocked blocked, $shortTerm short-term), ${activeWarnings.length} warnings ($severeWarnings severe)$weather

${roadworks.isEmpty ? '' : 'Roadworks:\n${roadworks.take(4).map((r) => '• ${r.isBlocked ? '🚫 ' : ''}${r.title} (${r.typeLabel}) - ${r.timeInfo}${r.speedLimit != null ? ', max ${r.speedLimit}' : ''}').join('\n')}'}

${activeWarnings.isEmpty ? '' : 'Warnings:\n${activeWarnings.take(3).map((w) => '• ${w.severity.label}: ${w.title}${w.endTime != null ? ' (${w.relativeTimeInfo})' : ''}${w.instruction != null ? ' → ${w.instruction}' : ''}').join('\n')}'}

Focus: hazards, weather impact, precautions. Be practical.''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'No summary available.';
      _cache[key] = _CachedSummary(text);
      return text;
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }


  /// Generates a safety summary for a specific location including warnings, air quality, flood, and weather data.
  static Future<String> generateLocationSummary(
    String location,
    List<WarningItem> warnings, {
    double? radiusKm,
    OpenMeteoAirQualityDto? airQuality,
    OpenMeteoFloodDto? floodData,
    WeatherDto? currentWeather,
  }) async {
    _cleanupCache();
    final activeWarnings = warnings.where((w) => w.isActive).toList();
    final radiusKey = radiusKm != null ? ':${radiusKm.toInt()}km' : '';
    final aqKey = airQuality != null ? ':aq${airQuality.usAqi}' : '';
    final floodKey = floodData != null ? ':fl${floodData.riverDischarge}' : '';
    final weatherKey = currentWeather != null ? ':w${currentWeather.weatherCode}' : '';
    final key = 'loc:$location$radiusKey:${activeWarnings.length}$aqKey$floodKey$weatherKey';
    if (_cache[key]?.isValid == true) return _cache[key]!.text;

    final apiKey = await ApiKeyService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key required - please configure in Settings.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
      final severeCount = activeWarnings.where((w) => w.severity.level >= 3).length;
      
      // Builds concise environment info.
      String envInfo = '';
      if (currentWeather != null) {
        envInfo += '\n- Weather: ${currentWeather.icon} ${currentWeather.temperature?.toStringAsFixed(0)}°C, ${currentWeather.description}';
        if (currentWeather.windSpeed != null) envInfo += ', Wind ${currentWeather.windSpeed!.toStringAsFixed(0)}km/h';
      }
      
      if (airQuality != null) {
        envInfo += '\n- Air Quality: AQI ${airQuality.usAqi} (PM2.5: ${airQuality.pm25?.toStringAsFixed(1)})';
      }
      
      if (floodData != null && floodData.riverDischarge != null) {
        envInfo += '\n- Flood Risk: River discharge ${floodData.riverDischarge?.toStringAsFixed(1)} ${floodData.unit ?? 'm³/s'}';
      }
      
      final prompt = '''Brief English safety summary (max 4 sentences) for $location${radiusKm != null ? ' (radius ${radiusKm.toInt()}km)' : ''}.

Status: ${activeWarnings.length} active warnings ($severeCount severe)$envInfo

${activeWarnings.isEmpty ? '' : 'Warnings:\n${activeWarnings.take(5).map((w) => '• ${w.severity.label}: ${w.title}${w.endTime != null ? ' (Ends ${w.relativeTimeInfo})' : ''}${w.instruction != null ? ' → ${w.instruction}' : ''}').join('\n')}'}

Focus: immediate safety, health risks, practical advice.''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'No summary available.';
      _cache[key] = _CachedSummary(text);
      return text;
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }
}
