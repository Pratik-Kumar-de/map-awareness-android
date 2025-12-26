import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/services/api_key_service.dart';

// Cache for AI summaries (15 min TTL)
final Map<String, _CachedSummary> _cache = {};

class _CachedSummary {
  final String text;
  final DateTime time;
  _CachedSummary(this.text) : time = DateTime.now();
  bool get isValid => DateTime.now().difference(time).inMinutes < 15;
}

/// Generates AI summary for route conditions
Future<String> generateRouteSummary(
  List<RoutingWidgetData> roadworks,
  List<WarningItem> warnings,
  String start,
  String end,
) async {
  final key = 'route:$start:$end:${roadworks.length}:${warnings.length}';
  if (_cache[key]?.isValid == true) return _cache[key]!.text;

  final apiKey = await ApiKeyService.getGeminiKey();
  if (apiKey == null || apiKey.isEmpty) {
    return 'API key required - please configure in Settings.';
  }

  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
    final blockedCount = roadworks.where((r) => r.isBlocked).length;
    final prompt = '''Generate a brief English travel safety summary (max 4 sentences) for driving from $start to $end.

Route overview:
- ${roadworks.length} total roadworks ($blockedCount blocked/closed)
- ${warnings.length} active warnings

Roadworks: ${roadworks.isEmpty ? 'None' : roadworks.take(5).map((r) => '${r.title} (${r.typeLabel})').join('; ')}
Warnings: ${warnings.isEmpty ? 'None' : warnings.take(3).map((w) => '${w.title} - ${w.severity.label}').join('; ')}

Focus on: key hazards, recommended precautions, and overall trip outlook. Be concise and practical.''';
    
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? 'No summary available.';
    _cache[key] = _CachedSummary(text);
    return text;
  } catch (e) {
    return 'Error generating summary: $e';
  }
}

/// Generates AI summary for location warnings, air quality, and flood data
Future<String> generateLocationSummary(
  String location,
  List<WarningItem> warnings, {
  double? radiusKm,
  Map<String, dynamic>? airQuality,
  Map<String, dynamic>? floodData,
}) async {
  final radiusKey = radiusKm != null ? ':${radiusKm.toInt()}km' : '';
  final aqKey = airQuality != null ? ':aq${airQuality['aqi']}' : '';
  final floodKey = floodData != null ? ':fl${floodData['discharge']}' : '';
  final key = 'loc:$location$radiusKey:${warnings.length}$aqKey$floodKey';
  if (_cache[key]?.isValid == true) return _cache[key]!.text;

  final apiKey = await ApiKeyService.getGeminiKey();
  if (apiKey == null || apiKey.isEmpty) {
    return 'API key required - please configure in Settings.';
  }

  try {
    final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
    final radiusInfo = radiusKm != null ? ' within ${radiusKm.toInt()} km' : '';
    final severeCount = warnings.where((w) => w.severity.level >= 3).length;
    
    // Build air quality info
    String airQualityInfo = 'Not available';
    if (airQuality != null) {
      final aqi = airQuality['aqi'];
      final pm25 = airQuality['pm2_5'];
      final pm10 = airQuality['pm10'];
      airQualityInfo = 'AQI: $aqi, PM2.5: ${pm25?.toStringAsFixed(1)} µg/m³, PM10: ${pm10?.toStringAsFixed(1)} µg/m³';
    }
    
    // Build flood info
    String floodInfo = 'Not available';
    if (floodData != null) {
      final discharge = floodData['discharge'];
      floodInfo = 'River discharge: ${discharge?.toStringAsFixed(1)} m³/s';
    }
    
    final prompt = '''Generate a brief English safety summary (max 4 sentences) for $location$radiusInfo.

Current status:
- ${warnings.length} weather/safety alerts ($severeCount severe/extreme)
- Air Quality: $airQualityInfo
- Flood Risk: $floodInfo
- Categories: ${warnings.map((w) => w.category.name).toSet().join(', ')}

Active warnings: ${warnings.isEmpty ? 'None' : warnings.take(5).map((w) => '${w.title} (${w.severity.label})').join('; ')}

Focus on: immediate safety concerns including air quality health effects, flood risks, and practical advice for residents/visitors.''';
    
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? 'No summary available.';
    _cache[key] = _CachedSummary(text);
    return text;
  } catch (e) {
    return 'Error generating summary: $e';
  }
}

