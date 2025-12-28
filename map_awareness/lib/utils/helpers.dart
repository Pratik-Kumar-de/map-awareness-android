import 'package:intl/intl.dart';

/// Safe bool parser for JSON
bool safeBool(dynamic v) => v == true || v == 'true';

/// Finds value in list by prefix match
String? findByPrefix(List<String>? lines, String prefix) {
  if (lines == null) return null;
  for (final line in lines) {
    if (line.contains(prefix)) return line.replaceAll('$prefix:', '').trim();
  }
  return null;
}

/// Checks if coordinate is within bounds with buffer
bool isCoordinateInBounds(double? lat, double? lng, double minLat, double maxLat, double minLng, double maxLng, {double buffer = 0.02}) {
  if (lat == null || lng == null) return true;
  return lat >= minLat - buffer && lat <= maxLat + buffer &&
         lng >= minLng - buffer && lng <= maxLng + buffer;
}

/// Formats a time range string (e.g. "12.05, 14:00 - 16:00")
String formatTimeRange(DateTime? start, DateTime? end) {
  final df = DateFormat('dd.MM');
  final tf = DateFormat('HH:mm');

  if (start == null && end == null) return 'Ongoing';
  if (start != null && end != null) {
    if (start.day == end.day && start.month == end.month) {
      return '${df.format(start)}, ${tf.format(start)} - ${tf.format(end)}';
    }
    return '${df.format(start)} - ${df.format(end)}';
  }
  if (start != null) return 'From ${df.format(start)}';
  return 'Until ${df.format(end!)}';
}
