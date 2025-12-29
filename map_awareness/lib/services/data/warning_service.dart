
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
  static Future<List<DwdWarningDto>> getDwdWarnings() => 
      DioClient.safeGetList(
        '$_dwdBaseUrl/gemeinde_warnings_v2.json',
        listKey: 'warnings',
        fromJson: DwdWarningDto.fromJson,
        options: DioClient.shortCache(),
      );

  /// Fetches NINA warnings for a specific city name by resolving its ARS code.
  static Future<List<NinaWarningDto>> getNinaWarningsForCity(String cityName) async {
    final ars = lookupARSForCity(cityName);
    if (ars == null) return [];
    return getNinaWarningsForArs(ars);
  }

  /// Fetches NINA warnings using the Amtlicher Regionalschlüssel (ARS).
  static Future<List<NinaWarningDto>> getNinaWarningsForArs(String ars) {
    final arsPrefix = ars.length >= 5 ? ars.substring(0, 5) : ars;
    return DioClient.safeGetList(
      '$_ninaBaseUrl/dashboard/$arsPrefix.json',
      fromJson: NinaWarningDto.fromJson,
      options: DioClient.shortCache(),
    );
  }

  static Future<List<WarningItem>> getUnifiedWarningsForCities(List<String> cities) async {
    final uniqueCities = cities.map((c) => c.trim().toLowerCase()).where((c) => c.isNotEmpty).toSet();
    
    final results = await Future.wait([
      getDwdWarnings(),
      Future.wait(uniqueCities.map(getNinaWarningsForCity)),
    ]);

    final all = [
      ...(results[0] as List<DwdWarningDto>).map(WarningItem.fromDWD),
      ...(results[1] as List<List<NinaWarningDto>>).expand((l) => l).map(WarningItem.fromNINA),
    ];

    final seen = <String>{};
    return all.where((w) => seen.add(w.title)).toList()..sort();
  }
}
