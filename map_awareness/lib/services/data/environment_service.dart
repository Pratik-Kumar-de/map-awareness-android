import 'package:clock/clock.dart';
import 'package:map_awareness/services/core/dio_client.dart';
import 'package:map_awareness/models/dto/dto.dart';

/// Service for fetching environmental data like air quality, flood warnings, and weather.
class EnvironmentService {
  static const _airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const _floodUrl = 'https://flood-api.open-meteo.com/v1/flood';

  EnvironmentService._();

  /// Fetches current air quality metrics (US AQI, PM10, PM2.5) for given coordinates.
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

  /// Fetches river discharge forecast for flood analysis.
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

  /// Fetches current or forecasted weather data depending on the provided time preference.
  static Future<WeatherDto?> getWeather(double lat, double lng, {DateTime? forecastTime}) async {
    try {
      final now = clock.now();
      final isForecast = forecastTime != null && forecastTime.isAfter(now);

      final res = await DioClient.instance.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          if (isForecast) 'hourly': 'temperature_2m,weather_code,wind_speed_10m,precipitation',
          if (!isForecast) 'current': 'temperature_2m,weather_code,wind_speed_10m,precipitation',
          'timezone': 'auto',
          if (isForecast) 'forecast_days': 7,
        },
        options: DioClient.shortCache(),
      );

      if (isForecast) {
        // Finds closest hour.
        final hourly = res.data['hourly'];
        final times = (hourly?['time'] as List?)?.map((e) => DateTime.parse(e as String)).toList();
        if (times == null || times.isEmpty) return null;

        final closestIndex = times.indexed.reduce((a, b) {
          final aDiff = (a.$2.difference(forecastTime).inMinutes).abs();
          final bDiff = (b.$2.difference(forecastTime).inMinutes).abs();
          return aDiff < bDiff ? a : b;
        }).$1;


        return WeatherDto(
          temperature: (hourly['temperature_2m'][closestIndex] as num?)?.toDouble(),
          weatherCode: hourly['weather_code'][closestIndex] as int?,
          windSpeed: (hourly['wind_speed_10m'][closestIndex] as num?)?.toDouble(),
          precipitation: (hourly['precipitation'][closestIndex] as num?)?.toDouble(),
        );
      } else {
        if (res.data['current'] == null) return null;
        return WeatherDto.fromJson(res.data['current']);
      }
    } catch (_) {
      return null;
    }
  }
}

