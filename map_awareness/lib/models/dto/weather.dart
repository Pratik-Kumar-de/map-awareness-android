import 'package:json_annotation/json_annotation.dart';

part 'weather.g.dart';

/// Data Transfer Object for OpenMeteo weather response.
@JsonSerializable(createToJson: false)
class WeatherDto {
  @JsonKey(name: 'temperature_2m')
  final double? temperature;

  @JsonKey(name: 'weather_code')
  final int? weatherCode;

  @JsonKey(name: 'wind_speed_10m')
  final double? windSpeed;

  @JsonKey(name: 'precipitation')
  final double? precipitation;

  WeatherDto({
    this.temperature,
    this.weatherCode,
    this.windSpeed,
    this.precipitation,
  });

  factory WeatherDto.fromJson(Map<String, dynamic> json) => _$WeatherDtoFromJson(json);

  /// Maps WMO weather code to English description.
  String get description {
    if (weatherCode == null) return 'Unknown';
    switch (weatherCode!) {
      case 0: return 'Clear';
      case 1: case 2: case 3: return 'Partly Cloudy';
      case 45: case 48: return 'Foggy';
      case 51: case 53: case 55: return 'Drizzle';
      case 61: case 63: case 65: return 'Rain';
      case 71: case 73: case 75: return 'Snow';
      case 95: case 96: case 99: return 'Thunderstorm';
      default: return 'Cloudy';
    }
  }

  /// Maps WMO weather code to representative emoji icon.
  String get icon {
    if (weatherCode == null) return '🌡️';
    switch (weatherCode!) {
      case 0: return '☀️';
      case 1: case 2: case 3: return '⛅';
      case 45: case 48: return '🌫️';
      case 51: case 53: case 55: return '🌦️';
      case 61: case 63: case 65: return '🌧️';
      case 71: case 73: case 75: return '🌨️';
      case 95: case 96: case 99: return '⛈️';
      default: return '☁️';
    }
  }
}
