import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/helpers.dart';

/// Enum defining warning severity levels with associated metadata/colors.
/// Colors are inlined to keep the domain model self-contained.
enum WarningSeverity {
  minor(1, 'Minor', 'Low risk', Color(0xFF42A5F5), Color(0xFF1E88E5)),
  moderate(2, 'Moderate', 'Be prepared', Color(0xFFFFA000), Color(0xFFF57C00)),
  severe(3, 'Severe', 'Take action', Color(0xFFFF6D00), Color(0xFFE65100)),
  extreme(4, 'Extreme', 'Immediate danger', Color(0xFFE53935), Color(0xFFC62828));

  final int level;
  final String label;
  final String hint;
  final Color color;
  final Color darkColor;
  const WarningSeverity(this.level, this.label, this.hint, this.color, this.darkColor);

  /// Returns the appropriate color for the current theme brightness.
  Color colorIn(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkColor : color;

  List<Color> get gradient => [color, darkColor];

  /// Maps numeric level (1-4) to Severity enum.
  static WarningSeverity fromLevel(int level) {
    if (level >= 4) return extreme;
    if (level >= 3) return severe;
    if (level >= 2) return moderate;
    return minor;
  }
}

/// Enum categorizing warnings based on type/event strings.
enum WarningCategory {
  weather,
  flood,
  fire,
  health,
  civil,
  environment,
  other;

  /// Infers category from raw type and event strings using keyword matching.
  static WarningCategory fromType(String type, String event) {
    final lower = '${type.toLowerCase()} ${event.toLowerCase()}';
    if (lower.contains('flood') || lower.contains('water') || lower.contains('high water')) {
      return flood;
    }
    if (lower.contains('fire') || lower.contains('blaze') || lower.contains('fire')) {
      return fire;
    }
    if (lower.contains('health') || lower.contains('wellness') || lower.contains('corona')) {
      return health;
    }
    if (lower.contains('civil') || lower.contains('population') || lower.contains('warning')) {
      return civil;
    }
    if (lower.contains('weather') || lower.contains('wind') ||
        lower.contains('storm') || lower.contains('thunderstorm') || lower.contains('snow') ||
        lower.contains('frost') || lower.contains('heat') || lower.contains('fog')) {
      return weather;
    }
    if (lower.contains('air') || lower.contains('quality') || lower.contains('environment')) {
      return environment;
    }
    return other;
  }
}

/// Unified domain model aggregating warnings from multiple sources (DWD, NINA, OpenMeteo).
class WarningItem implements Comparable<WarningItem> {
  final String source;
  final WarningSeverity severity;
  final WarningCategory category;
  final String title;
  final String description;
  final String? instruction;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? latitude;
  final double? longitude;

  WarningItem({
    required this.source,
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    this.instruction,
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
  });

  /// Sorts by severity then start time.
  @override
  int compareTo(WarningItem other) {
    final severityCompare = other.severity.level.compareTo(severity.level);
    if (severityCompare != 0) return severityCompare;
    if (startTime != null && other.startTime != null) {
      return startTime!.compareTo(other.startTime!);
    }
    return 0;
  }

  /// Adapts DWD API object to unified WarningItem.
  factory WarningItem.fromDWD(DwdWarningDto w) => WarningItem(
        source: 'DWD',
        severity: WarningSeverity.fromLevel(w.level),
        category: WarningCategory.fromType('weather', w.event),
        title: w.headline.isNotEmpty ? w.headline : w.event,
        description: w.effectiveDescription,
        instruction: w.instruction,
        startTime: w.start > 0 ? DateTime.fromMillisecondsSinceEpoch(w.start) : null,
        endTime: w.end > 0 ? DateTime.fromMillisecondsSinceEpoch(w.end) : null,
      );

  /// Adapts NINA API object to unified WarningItem.
  factory WarningItem.fromNINA(NinaWarningDto w) => WarningItem(
        source: 'NINA',
        severity: _severityFromString(w.severity),
        category: WarningCategory.fromType(w.type, w.title),
        title: w.title,
        description: w.description,
        instruction: w.payload?['instruction'] ?? w.payload?['recommendations'],
        startTime: w.sent.isNotEmpty ? DateTime.tryParse(w.sent) : null,
      );

  /// Converts Air Quality DTO to a warning item if valid AQI exists.
  static WarningItem? fromOpenMeteoAirQuality(OpenMeteoAirQualityDto data) {
      final aqi = data.usAqi;
      if (aqi == null) return null;
      
      WarningSeverity sev = WarningSeverity.minor;
      String desc = 'Good air quality';
      if (aqi > 50) { sev = WarningSeverity.moderate; desc = 'Moderate'; }
      if (aqi > 100) { sev = WarningSeverity.severe; desc = 'Unhealthy'; }
      if (aqi > 200) { sev = WarningSeverity.extreme; desc = 'Very Unhealthy air quality'; }

      return WarningItem(
          source: 'OpenMeteo',
          severity: sev,
          category: WarningCategory.environment,
          title: 'Air Quality: $desc',
          description: 'US AQI: $aqi\nPM10: ${data.pm10} | PM2.5: ${data.pm25}',
          startTime: clock.now(),
      );
  }

  /// Converts Flood DTO to a warning item if discharge data exists.
  static WarningItem? fromOpenMeteoFlood(OpenMeteoFloodDto data) {
     final discharge = data.riverDischarge;
     final unit = data.unit ?? 'm³/s';
     
     if (discharge == null) return null;

     return WarningItem(
         source: 'OpenMeteo',
         severity: WarningSeverity.minor, 
         category: WarningCategory.flood,
         title: 'River Discharge',
         description: 'Current Level: $discharge $unit',
         startTime: clock.now(),
     );
  }

  static WarningSeverity _severityFromString(String s) {
    switch (s.toLowerCase()) {
      case 'extreme': return WarningSeverity.extreme;
      case 'severe': return WarningSeverity.severe;
      case 'moderate': return WarningSeverity.moderate;
      default: return WarningSeverity.minor;
    }
  }

  // Display helpers.

  /// Checks if active.
  bool get isActive {
    final now = clock.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  /// Checks if ended.
  bool get hasEnded => endTime != null && clock.now().isAfter(endTime!);

  /// Formats time range.
  String get formattedTimeRange => formatTimeRange(startTime, endTime);

  /// Formats relative time.
  String get relativeTimeInfo {
    final now = clock.now();

    if (startTime != null && now.isBefore(startTime!)) {
      return 'Starts ${timeago.format(startTime!, allowFromNow: true)}';
    }

    if (endTime != null) {
      if (now.isAfter(endTime!)) return 'Ended ${timeago.format(endTime!)}';
      return 'Ends ${timeago.format(endTime!, allowFromNow: true)}';
    }

    if (startTime != null) return 'Started ${timeago.format(startTime!)}';
    return 'Active now';
  }
}
