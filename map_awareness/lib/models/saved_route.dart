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
    startLat: (json['startLat'] as num).toDouble(),
    startLng: (json['startLng'] as num).toDouble(),
    endLat: (json['endLat'] as num).toDouble(),
    endLng: (json['endLng'] as num).toDouble(),
  );
}

class SavedRoute {
  final String id;
  final String name;
  final String startCoordinate;
  final String endCoordinate;
  final String startLocation; // City/address name for display
  final String endLocation;   // City/address name for display
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startCoordinate': startCoordinate,
    'endCoordinate': endCoordinate,
    'startLocation': startLocation,
    'endLocation': endLocation,
    'autobahnSegments': autobahnSegments.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
    id: json['id'],
    name: json['name'],
    startCoordinate: json['startCoordinate'],
    endCoordinate: json['endCoordinate'],
    // Fallback to coordinates if old data doesn't have location names
    startLocation: json['startLocation'] ?? json['startCoordinate'],
    endLocation: json['endLocation'] ?? json['endCoordinate'],
    autobahnSegments: (json['autobahnSegments'] as List)
        .map((e) => AutobahnData.fromJson(e))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
