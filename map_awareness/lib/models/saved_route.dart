import 'package:json_annotation/json_annotation.dart';

part 'saved_route.g.dart';

@JsonSerializable()
class AutobahnData {
  final String name;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

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

@JsonSerializable()
class SavedRoute {
  final String id;
  final String name;
  final String startCoordinate;
  final String endCoordinate;
  final String startLocation;
  final String endLocation;
  final List<AutobahnData> autobahnSegments;
  final DateTime createdAt;

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
