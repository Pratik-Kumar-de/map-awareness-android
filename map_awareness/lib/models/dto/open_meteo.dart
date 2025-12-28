import 'package:json_annotation/json_annotation.dart';

part 'open_meteo.g.dart';

@JsonSerializable(createToJson: false)
class OpenMeteoAirQualityDto {
  @JsonKey(name: 'us_aqi')
  final num? usAqi;

  @JsonKey(name: 'pm10')
  final num? pm10;

  @JsonKey(name: 'pm2_5')
  final num? pm25;

  OpenMeteoAirQualityDto({
    this.usAqi,
    this.pm10,
    this.pm25,
  });

  factory OpenMeteoAirQualityDto.fromJson(Map<String, dynamic> json) => _$OpenMeteoAirQualityDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class OpenMeteoFloodDto {
  @JsonKey(name: 'river_discharge')
  final double? riverDischarge;

  @JsonKey(name: 'unit')
  final String? unit;

  OpenMeteoFloodDto({
    this.riverDischarge,
    this.unit,
  });

  factory OpenMeteoFloodDto.fromJson(Map<String, dynamic> json) => _$OpenMeteoFloodDtoFromJson(json);
}
