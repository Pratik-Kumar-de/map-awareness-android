import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Haptic feedback helpers.
class Haptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void select() => HapticFeedback.selectionClick();
}

/// Safely parses a dynamic value to boolean (handles bool types and 'true' strings).
bool safeBool(dynamic v) => v == true || v == 'true';

/// Utility class providing static helper methods for data parsing and extraction.
class Helpers {

  /// Parses a string line by line to find a value after a given prefix.
  static String? findByPrefix(List<String>? lines, String prefix) {
    if (lines == null) return null;
    for (final line in lines) {
      if (line.contains(prefix)) return line.replaceAll('$prefix:', '').trim();
    }
    return null;
  }
}



/// Formats a start and end DateTime into a readable range string (e.g. "HH:mm - HH:mm" or "dd.MM").
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
