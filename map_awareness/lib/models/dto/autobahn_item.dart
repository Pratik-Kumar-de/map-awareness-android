import 'package:json_annotation/json_annotation.dart';
import 'geo_coordinate.dart';

/// Base Data Transfer Object for autobahn items (Roadworks, Charging Stations, Parking).
abstract class AutobahnItemDto {
  @JsonKey(defaultValue: '') final String identifier;
  @JsonKey(defaultValue: '') final String title;
  @JsonKey(defaultValue: '') final String subtitle;
  final GeoCoordinate? coordinate;
  final List<String>? description;

  AutobahnItemDto({
    required this.identifier,
    required this.title,
    required this.subtitle,
    this.coordinate,
    this.description,
  });

  /// Latitude of the item.
  double? get latitude => coordinate?.latitude;

  /// Longitude of the item.
  double? get longitude => coordinate?.longitude;

  /// Joins multiline description list into single text block.
  String get descriptionText => description?.join('\n') ?? '';
}
