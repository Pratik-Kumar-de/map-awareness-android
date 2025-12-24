class SavedLocation {
  final String id;
  final String name;
  final String locationText;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'locationText': locationText,
    'radiusKm': radiusKm,
    'createdAt': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    id: json['id'],
    name: json['name'],
    locationText: json['locationText'],
    radiusKm: json['radiusKm'],
    createdAt: DateTime.parse(json['createdAt']),
    latitude: json['latitude'],
    longitude: json['longitude'],
  );
}

