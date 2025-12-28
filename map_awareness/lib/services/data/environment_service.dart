
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/models/dto/dto.dart';

/// Handles environmental data: Air quality and flood information from Open-Meteo
class EnvironmentService {
  static const _airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const _floodUrl = 'https://flood-api.open-meteo.com/v1/flood';

  EnvironmentService._();

  /// Fetch air quality data (PM10, PM2.5, US AQI)
  static Future<OpenMeteoAirQualityDto?> getAirQuality(double lat, double lng) async {
    try {
      final res = await DioClient.instance.get(
        _airQualityUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current': 'us_aqi,pm10,pm2_5',
          'timezone': 'auto',
        },
        options: DioClient.shortCache(),
      );
      if (res.data['current'] == null) return null;
      return OpenMeteoAirQualityDto.fromJson(res.data['current']);
    } catch (_) {
      return null;
    }
  }

  /// Fetch flood data (River Discharge)
  static Future<OpenMeteoFloodDto?> getFloodData(double lat, double lng) async {
    try {
      final res = await DioClient.instance.get(
        _floodUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'daily': 'river_discharge_mean',
          'forecast_days': 1,
          'timezone': 'auto',
        },
        options: DioClient.shortCache(),
      );

      final daily = res.data['daily'];
      final discharge = (daily?['river_discharge_mean'] as List?)?.firstOrNull;
      if (discharge == null) return null;

      final unit = res.data['daily_units']?['river_discharge_mean'] as String?;

      return OpenMeteoFloodDto(
        riverDischarge: (discharge as num).toDouble(),
        unit: unit,
      );
    } catch (_) {
      return null;
    }
  }
}
