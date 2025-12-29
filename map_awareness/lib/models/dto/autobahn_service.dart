import 'package:json_annotation/json_annotation.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'geo_coordinate.dart';
import 'autobahn_item.dart';

part 'autobahn_service.g.dart';

/// Data Transfer Object for electric charging stations on the autobahn.
@JsonSerializable(createToJson: false)
class ChargingStationDto extends AutobahnItemDto {

  ChargingStationDto({
    required super.identifier,
    required super.title,
    required super.subtitle,
    super.coordinate,
    super.description,
  });

  factory ChargingStationDto.fromJson(Map<String, dynamic> json) => _$ChargingStationDtoFromJson(json);
}

/// Data Transfer Object for parking areas, including lorry specific parking.
@JsonSerializable(createToJson: false)
class ParkingDto extends AutobahnItemDto {
  @JsonKey(name: 'lorryParking', fromJson: safeBool) final bool isLorryParking;

  ParkingDto({
    required super.identifier,
    required super.title,
    required super.subtitle,
    super.coordinate,
    super.description,
    this.isLorryParking = false,
  });

  factory ParkingDto.fromJson(Map<String, dynamic> json) => _$ParkingDtoFromJson(json);
}
