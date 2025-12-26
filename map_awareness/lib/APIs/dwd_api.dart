import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_awareness/services/cache_service.dart';

/// DWD warning data from WarnWetter API
class DWDWarning {
  final int type;
  final int level; // 1-4 severity
  final String event;
  final String headline;
  final String description;
  final int start;
  final int end;

  DWDWarning({
    required this.type,
    required this.level,
    required this.event,
    required this.headline,
    required this.description,
    required this.start,
    required this.end,
  });
}

const String _dwdBaseUrl = 'https://s3.eu-central-1.amazonaws.com/app-prod-static.warnwetter.de/v16';

/// Fetches all DWD warnings (cached 15 min in-memory)
Future<List<DWDWarning>> getAllDWDWarnings() async {
  // Check cache
  final cached = CacheService.getCachedDWDWarnings();
  if (cached != null) return cached;

  final res = await http.get(Uri.parse('$_dwdBaseUrl/gemeinde_warnings_v2.json'));
  if (res.statusCode != 200) return [];

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final warnings = <DWDWarning>[];

  // Parse warnings array
  final rawWarnings = data['warnings'] as List? ?? [];
  for (final w in rawWarnings) {
    warnings.add(DWDWarning(
      type: (w['type'] as num?)?.toInt() ?? 0,
      level: (w['level'] as num?)?.toInt() ?? 1,
      event: w['event'] ?? '',
      headline: w['headLine'] ?? '',
      description: w['descriptionText'] ?? w['description'] ?? '',
      start: (w['start'] as num?)?.toInt() ?? 0,
      end: (w['end'] as num?)?.toInt() ?? 0,
    ));
  }

  CacheService.cacheDWDWarnings(warnings);
  return warnings;
}
