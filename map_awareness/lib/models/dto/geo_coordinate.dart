import 'package:json_annotation/json_annotation.dart';

part 'geo_coordinate.g.dart';

/// Shared coordinate class for all Autobahn API DTOs
@JsonSerializable(createToJson: false)
class GeoCoordinate {
  final dynamic lat;
  final dynamic long;
  GeoCoordinate({required this.lat, required this.long});

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) => _$GeoCoordinateFromJson(json);

  double? get latitude => lat is num ? (lat as num).toDouble() : (lat is String ? double.tryParse(lat as String) : null);
  double? get longitude => long is num ? (long as num).toDouble() : (long is String ? double.tryParse(long as String) : null);
}
