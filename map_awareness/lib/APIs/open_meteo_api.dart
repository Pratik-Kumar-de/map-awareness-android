import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoApi {
  static const String _airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _floodUrl = 'https://flood-api.open-meteo.com/v1/flood';

  /// Fetches air quality data (PM10, PM2.5, US AQI) for a specific location.
  static Future<Map<String, dynamic>?> getAirQuality(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_airQualityUrl?latitude=$lat&longitude=$lng&current=us_aqi,pm10,pm2_5&timezone=auto');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['current'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Fetches flood data (River Discharge) for a specific location.
  /// Note: This model is limited in coverage, so might return null often.
  static Future<Map<String, dynamic>?> getFloodData(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_floodUrl?latitude=$lat&longitude=$lng&daily=river_discharge_mean&forecast_days=1&timezone=auto');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['daily'] != null && 
            data['daily']['river_discharge_mean'] != null && 
            (data['daily']['river_discharge_mean'] as List).isNotEmpty) {
          
          final discharge = data['daily']['river_discharge_mean'][0];
          if (discharge == null) return null; // No data for this point

          return {
            'river_discharge': discharge,
            'unit': data['daily_units']['river_discharge_mean'],
          };
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
