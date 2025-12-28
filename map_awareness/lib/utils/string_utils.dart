/// Utility extensions for string manipulation including city extraction and coordinate validation.
extension StringSafety on String {
  static final _coordPattern = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');

  /// Extracts the first part of a comma-separated string, typically the city name.
  String get cityName => split(',').first.trim();

  /// Checks if the string matches a latitude/longitude coordinate pair pattern.
  bool get isCoordinates => _coordPattern.hasMatch(trim());

  /// Removes spaces from a coordinate string for API usage.
  String get normalizeCoords => replaceAll(' ', '');
}
