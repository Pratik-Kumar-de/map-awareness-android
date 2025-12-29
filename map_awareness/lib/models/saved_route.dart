import 'package:json_annotation/json_annotation.dart';

part 'saved_route.g.dart';

/// Data model representing a specific autobahn segment (start/end points).
@JsonSerializable()
class AutobahnData {
  final String name; // Road identifier (e.g. A1)
  final double startLat; // Segment start latitude
  final double startLng; // Segment start longitude
  final double endLat; // Segment end latitude
  final double endLng; // Segment end longitude

  AutobahnData({
    required this.name,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  factory AutobahnData.fromJson(Map<String, dynamic> json) => _$AutobahnDataFromJson(json);
  Map<String, dynamic> toJson() => _$AutobahnDataToJson(this);
}

/// Entity representing a fully defined user-saved route with segments and metadata.
@JsonSerializable()
class SavedRoute {
  final String id; // Unique identifier
  final String name; // Route label
  final String startCoordinate; // Start lat,lng string
  final String endCoordinate; // End lat,lng string
  final String startLocation; // Resolved start address
  final String endLocation; // Resolved end address
  final List<AutobahnData> autobahnSegments; // List of road segments
  final DateTime createdAt; // Creation timestamp

  SavedRoute({
    required this.id,
    required this.name,
    required this.startCoordinate,
    required this.endCoordinate,
    required this.startLocation,
    required this.endLocation,
    required this.autobahnSegments,
    required this.createdAt,
  });

  factory SavedRoute.fromJson(Map<String, dynamic> json) => _$SavedRouteFromJson(json);
  Map<String, dynamic> toJson() => _$SavedRouteToJson(this);
}
