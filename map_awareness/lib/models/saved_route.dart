import 'dart:convert';

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

  Map<String, dynamic> toJson() => {
    'name': name,
    'startLat': startLat,
    'startLng': startLng,
    'endLat': endLat,
    'endLng': endLng,
  };

  factory AutobahnData.fromJson(Map<String, dynamic> json) => AutobahnData(
    name: json['name'],
    startLat: json['startLat'],
    startLng: json['startLng'],
    endLat: json['endLat'],
    endLng: json['endLng'],
  );
}

class SavedRoute {
  final String id;
  final String name;
  final String startCoordinate;
  final String endCoordinate;
  final List<AutobahnData> autobahnSegments;
  final DateTime createdAt;

  SavedRoute({
    required this.id,
    required this.name,
    required this.startCoordinate,
    required this.endCoordinate,
    required this.autobahnSegments,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startCoordinate': startCoordinate,
    'endCoordinate': endCoordinate,
    'autobahnSegments': autobahnSegments.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'],
    name: json['name'],
    startCoordinate: json['startCoordinate'],
    endCoordinate: json['endCoordinate'],
    autobahnSegments: (json['autobahnSegments'] as List)
        .map((e) => AutobahnData.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );

  String toJsonString() => jsonEncode(toJson());

  factory SavedRoute.fromJsonString(String jsonString) =>
      SavedRoute.fromJson(jsonDecode(jsonString));
}
