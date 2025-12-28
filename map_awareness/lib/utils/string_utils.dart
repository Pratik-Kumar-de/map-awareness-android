extension StringSafety on String {
  /// Extracts city/name from "City, Region, Country" or "lat,lng"
  String get cityName => split(',').first.trim();

  /// Checks if string is a coordinate pair "lat,lng"
  bool get isCoordinates => RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(trim());

  /// Normalizes coordinates by removing spaces
  String get normalizeCoords => replaceAll(' ', '');
}
