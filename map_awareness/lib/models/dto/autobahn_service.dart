import 'package:json_annotation/json_annotation.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'geo_coordinate.dart';

part 'autobahn_service.g.dart';

/// Electric charging station from Autobahn API
@JsonSerializable(createToJson: false)
class ChargingStationDto {
  @JsonKey(defaultValue: '') final String identifier;
  @JsonKey(defaultValue: '') final String title;
  @JsonKey(defaultValue: '') final String subtitle;
  final GeoCoordinate? coordinate;
  final List<String>? description;

  ChargingStationDto({
    required this.identifier,
    required this.title,
    required this.subtitle,
    this.coordinate,
    this.description,
  });

  factory ChargingStationDto.fromJson(Map<String, dynamic> json) => _$ChargingStationDtoFromJson(json);

  double? get latitude => coordinate?.latitude;
  double? get longitude => coordinate?.longitude;
  String get descriptionText => description?.join('\n') ?? '';
}

/// Rest area / parking from Autobahn API
@JsonSerializable(createToJson: false)
class ParkingDto {
  @JsonKey(defaultValue: '') final String identifier;
  @JsonKey(defaultValue: '') final String title;
  @JsonKey(defaultValue: '') final String subtitle;
  final GeoCoordinate? coordinate;
  final List<String>? description;
  @JsonKey(name: 'lorryParking', fromJson: safeBool) final bool isLorryParking;

  ParkingDto({
    required this.identifier,
    required this.title,
    required this.subtitle,
    this.coordinate,
    this.description,
    this.isLorryParking = false,
  });

  factory ParkingDto.fromJson(Map<String, dynamic> json) => _$ParkingDtoFromJson(json);

  double? get latitude => coordinate?.latitude;
  double? get longitude => coordinate?.longitude;
  String get descriptionText => description?.join('\n') ?? '';
}
