
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/data/ars_lookup.dart';

/// Manages retrieval and aggregation of warning data from DWD and NINA.
class WarningService {
  static const _dwdBaseUrl = 'https://s3.eu-central-1.amazonaws.com/app-prod-static.warnwetter.de/v16';
  static const _ninaBaseUrl = 'https://warnung.bund.de/api31';

  WarningService._();


  /// Fetches weather warnings from DWD (German Weather Service).
  static Future<List<DwdWarningDto>> getDwdWarnings() async {
    try {
      final res = await DioClient.instance.get(
        '$_dwdBaseUrl/gemeinde_warnings_v2.json',
        options: DioClient.shortCache(),
      );

      final list = res.data['warnings'] as List? ?? [];
      return list.map((w) => DwdWarningDto.fromJson(w as Map<String, dynamic>)).toList();
    } catch (_) {
      // Silent fail: API unavailable or network error
      return [];
    }
  }

  /// Fetches NINA warnings for a specific city name by resolving its ARS code.
  static Future<List<NinaWarningDto>> getNinaWarningsForCity(String cityName) async {
    final ars = lookupARSForCity(cityName);
    if (ars == null) return [];
    return getNinaWarningsForArs(ars);
  }

  /// Fetches NINA warnings using the Amtlicher Regionalschlüssel (ARS).
  static Future<List<NinaWarningDto>> getNinaWarningsForArs(String ars) async {
    try {
      final arsPrefix = ars.length >= 5 ? ars.substring(0, 5) : ars;
      final res = await DioClient.instance.get(
        '$_ninaBaseUrl/dashboard/$arsPrefix.json',
        options: DioClient.shortCache(),
      );

      final list = res.data as List? ?? [];
      return list.map((w) => NinaWarningDto.fromJson(w as Map<String, dynamic>)).toList();
    } catch (_) {
      // Silent fail: API unavailable or network error
      return [];
    }
  }

  /// Aggregates warnings from DWD and NINA, ensuring uniqueness by title.
  static Future<List<WarningItem>> getUnifiedWarningsForCities(List<String> cities) async {
    final allWarnings = <WarningItem>[];
    
    // Adds DWD warnings.
    final dwd = await getDwdWarnings();
    allWarnings.addAll(dwd.map(WarningItem.fromDWD));

    // Adds NINA warnings.
    final seenCities = <String>{};
    for (final city in cities) {
      final normalized = city.trim().toLowerCase();
      if (normalized.isEmpty || !seenCities.add(normalized)) continue;
      
      final nina = await getNinaWarningsForCity(city);
      allWarnings.addAll(nina.map(WarningItem.fromNINA));
    }

    // Deduplicates by title.
    final seenTitles = <String>{};
    return allWarnings.where((w) => seenTitles.add(w.title)).toList()..sort();
  }
}
