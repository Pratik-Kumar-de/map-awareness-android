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

  /// Generates a travel safety summary for a route by constructing a prompt with roadworks and warnings, then querying the AI.
  static Future<String> generateRouteSummary(
    List<RoadworkDto> roadworks,
    List<WarningItem> warnings,
    String start,
    String end, {
    WeatherDto? departureWeather,
    WeatherDto? arrivalWeather,
  }) async {
    _cleanupCache();
    final key = 'route:$start:$end:${roadworks.length}:${warnings.length}';
    if (_cache[key]?.isValid == true) return _cache[key]!.text;

    final apiKey = await ApiKeyService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key required - please configure in Settings.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
      final blockedCount = roadworks.where((r) => r.isBlocked).length;
      
      // Builds weather info.
      String weatherInfo = '';
      if (departureWeather != null) {
        weatherInfo += '\nDeparture weather ($start): ${departureWeather.icon} ${departureWeather.description}, ${departureWeather.temperature?.toStringAsFixed(1)}°C';
        if (departureWeather.windSpeed != null) {
          weatherInfo += ', Wind: ${departureWeather.windSpeed!.toStringAsFixed(0)} km/h';
        }
        if (departureWeather.precipitation != null && departureWeather.precipitation! > 0) {
          weatherInfo += ', Rain: ${departureWeather.precipitation}mm';
        }
      }
      if (arrivalWeather != null) {
        weatherInfo += '\nArrival weather ($end): ${arrivalWeather.icon} ${arrivalWeather.description}, ${arrivalWeather.temperature?.toStringAsFixed(1)}°C';
        if (arrivalWeather.windSpeed != null) {
          weatherInfo += ', Wind: ${arrivalWeather.windSpeed!.toStringAsFixed(0)} km/h';
        }
        if (arrivalWeather.precipitation != null && arrivalWeather.precipitation! > 0) {
          weatherInfo += ', Rain: ${arrivalWeather.precipitation}mm';
        }
      }
      
      final prompt = '''Generate a brief English travel safety summary (max 4 sentences) for driving from $start to $end.

Route overview:
- ${roadworks.length} total roadworks ($blockedCount blocked/closed)
- ${warnings.length} active warnings$weatherInfo

Roadworks: ${roadworks.isEmpty ? 'None' : roadworks.take(5).map((r) => '${r.isBlocked ? '[BLOCKED] ' : ''}${r.title} (${r.typeLabel}) - ${r.subtitle}\nDetails: ${r.descriptionText.replaceAll('\n', ' ')}\nImpact: Length ${r.length ?? 'N/A'}, Speed ${r.speedLimit ?? 'N/A'}, Width ${r.maxWidth ?? 'N/A'}\nStatus: ${r.isFuture ? 'Future/Planned' : 'Active'} - ${r.timeInfo}').join(';\n')}
Warnings: ${warnings.isEmpty ? 'None' : warnings.take(3).map((w) => '${w.title} - ${w.severity.label} (${w.category.name})\nSource: ${w.source}\nDetails: ${w.description.replaceAll('\n', ' ')}\n${w.instruction != null ? 'Instruction: ${w.instruction!.replaceAll('\n', ' ')}\n' : ''}Time: ${w.relativeTimeInfo}${w.latitude != null ? '\nLocation: ${w.latitude!.toStringAsFixed(3)}, ${w.longitude!.toStringAsFixed(3)}' : ''}').join(';\n')}

Focus on: key hazards, weather impact on driving, recommended precautions, and overall trip outlook. Be concise and practical.''';
      
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
    final radiusKey = radiusKm != null ? ':${radiusKm.toInt()}km' : '';
    final aqKey = airQuality != null ? ':aq${airQuality.usAqi}' : '';
    final floodKey = floodData != null ? ':fl${floodData.riverDischarge}' : '';
    final weatherKey = currentWeather != null ? ':w${currentWeather.weatherCode}' : '';
    final key = 'loc:$location$radiusKey:${warnings.length}$aqKey$floodKey$weatherKey';
    if (_cache[key]?.isValid == true) return _cache[key]!.text;

    final apiKey = await ApiKeyService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'API key required - please configure in Settings.';
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
      final radiusInfo = radiusKm != null ? ' within ${radiusKm.toInt()} km' : '';
      final severeCount = warnings.where((w) => w.severity.level >= 3).length;
      
      // Builds weather info.
      String weatherInfo = 'Not available';
      if (currentWeather != null) {
        weatherInfo = '${currentWeather.icon} ${currentWeather.description}, ${currentWeather.temperature?.toStringAsFixed(1)}°C';
        if (currentWeather.windSpeed != null) weatherInfo += ', Wind: ${currentWeather.windSpeed!.toStringAsFixed(0)} km/h';
        if (currentWeather.precipitation != null && currentWeather.precipitation! > 0) {
          weatherInfo += ', Rain: ${currentWeather.precipitation}mm';
        }
      }
      
      // Builds air quality info.
      String airQualityInfo = 'Not available';
      if (airQuality != null) {
        final aqi = airQuality.usAqi;
        final pm25 = airQuality.pm25;
        final pm10 = airQuality.pm10;
        airQualityInfo = 'AQI: $aqi, PM2.5: ${pm25?.toStringAsFixed(1)} µg/m³, PM10: ${pm10?.toStringAsFixed(1)} µg/m³';
      }
      
      // Builds flood info.
      String floodInfo = 'Not available';
      if (floodData != null) {
        final discharge = floodData.riverDischarge;
        final unit = floodData.unit ?? 'm³/s';
        floodInfo = 'River discharge: ${discharge?.toStringAsFixed(1)} $unit';
      }
      
      final prompt = '''Generate a brief English safety summary (max 4 sentences) for $location$radiusInfo.
      
Current status:
- ${warnings.length} weather/safety alerts ($severeCount severe/extreme)
- Current Weather: $weatherInfo
- Air Quality: $airQualityInfo
- Flood Risk: $floodInfo
- Categories: ${warnings.map((w) => w.category.name).toSet().join(', ')}

Active warnings: ${warnings.isEmpty ? 'None' : warnings.take(5).map((w) => '${w.title} (${w.severity.label}) - ${w.source}\nCategory: ${w.category.name}\nDetails: ${w.description.replaceAll('\n', ' ')}\n${w.instruction != null ? 'Instruction: ${w.instruction!.replaceAll('\n', ' ')}\n' : ''}Time: ${w.relativeTimeInfo}').join(';\n')}

Focus on: immediate safety concerns including weather conditions, air quality health effects, flood risks, and practical advice for residents/visitors.''';
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'No summary available.';
      _cache[key] = _CachedSummary(text);
      return text;
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }
}
