import 'package:json_annotation/json_annotation.dart';

part 'saved_location.g.dart';

/// Entity representing a saved geographic location with radius preference.
@JsonSerializable()
class SavedLocation {
  final String id; // Unique identifier
  final String name; // User-defined label
  final String locationText; // Human-readable address
  @JsonKey(defaultValue: 20.0)
  final double radiusKm; // Alert radius in kilometers
  final DateTime createdAt; // Creation timestamp
  final double? latitude; // Geographic latitude
  final double? longitude; // Geographic longitude

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
