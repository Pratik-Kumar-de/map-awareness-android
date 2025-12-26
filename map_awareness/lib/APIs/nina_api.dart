import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_awareness/services/cache_service.dart';
import 'package:map_awareness/data/ars_lookup.dart';

/// NINA warning data from BBK API
class NINAWarning {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String description;
  final String sent;

  NINAWarning({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.sent,
  });
}

const String _ninaBaseUrl = 'https://warnung.bund.de/api31';

/// Fetches NINA warnings for a city name (cached 15 min)
Future<List<NINAWarning>> getNINAWarningsForCity(String cityName) async {
  final ars = lookupARSForCity(cityName);
  if (ars == null) return []; // City not in lookup - no false fallbacks
  return getNINAWarningsForARS(ars);
}

/// Fetches NINA warnings for an ARS code
Future<List<NINAWarning>> getNINAWarningsForARS(String ars) async {
  // Check cache
  final cached = CacheService.getCachedNINAWarnings(ars);
  if (cached != null) return cached;

  // Use 5-digit prefix for county-level
  final arsPrefix = ars.length >= 5 ? ars.substring(0, 5) : ars;
  final res = await http.get(Uri.parse('$_ninaBaseUrl/dashboard/$arsPrefix.json'));
  if (res.statusCode != 200) return [];

  final data = jsonDecode(res.body) as List? ?? [];
  final warnings = <NINAWarning>[];

  for (final w in data) {
    warnings.add(NINAWarning(
      id: w['id'] ?? '',
      type: w['type'] ?? '',
      severity: w['severity'] ?? 'Minor',
      title: w['i18nTitle']?['en'] ?? w['i18nTitle']?['de'] ?? w['payload']?['headline'] ?? '',
      description: w['i18nTitle']?['en'] ?? w['i18nTitle']?['de'] ?? '',
      sent: w['sent'] ?? '',
    ));
  }

  CacheService.cacheNINAWarnings(ars, warnings);
  return warnings;
}
