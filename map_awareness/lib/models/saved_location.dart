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

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    final radiusRaw = json['radiusKm'];
    final latRaw = json['latitude'];
    final lngRaw = json['longitude'];
    return SavedLocation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      locationText: json['locationText']?.toString() ?? '',
      radiusKm: radiusRaw is num ? radiusRaw.toDouble() : 20.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      latitude: latRaw is num ? latRaw.toDouble() : null,
      longitude: lngRaw is num ? lngRaw.toDouble() : null,
    );
  }
}
