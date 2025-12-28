import 'package:json_annotation/json_annotation.dart';

part 'saved_location.g.dart';

@JsonSerializable()
class SavedLocation {
  final String id;
  final String name;
  final String locationText;
  @JsonKey(defaultValue: 20.0)
  final double radiusKm;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  SavedLocation({
    required this.id,
    required this.name,
    required this.locationText,
    required this.radiusKm,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) => _$SavedLocationFromJson(json);
  Map<String, dynamic> toJson() => _$SavedLocationToJson(this);
}
