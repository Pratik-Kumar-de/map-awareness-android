import 'package:flutter/material.dart';

import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/helpers.dart';

/// Severity with centralized colors
enum WarningSeverity {
  minor(1, 'Minor', 'Low risk', AppTheme.severityMinor, Color(0xFF1E88E5)),
  moderate(2, 'Moderate', 'Be prepared', AppTheme.severityModerate, Color(0xFFF57C00)),
  severe(3, 'Severe', 'Take action', AppTheme.severitySevere, Color(0xFFE65100)),
  extreme(4, 'Extreme', 'Immediate danger', AppTheme.severityExtreme, Color(0xFFC62828));

  final int level;
  final String label;
  final String hint;
  final Color color;
  final Color darkColor;
  const WarningSeverity(this.level, this.label, this.hint, this.color, this.darkColor);

  List<Color> get gradient => [color, darkColor];

  static WarningSeverity fromLevel(int level) {
    if (level >= 4) return extreme;
    if (level >= 3) return severe;
    if (level >= 2) return moderate;
    return minor;
  }
}

/// Warning category for grouping & icons
enum WarningCategory {
  weather,
  flood,
  fire,
  health,
  civil,
  environment,
  other;

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

/// Unified warning model for DWD and NINA with rich display info
class WarningItem implements Comparable<WarningItem> {
  final String source;
  final WarningSeverity severity;
  final WarningCategory category;
  final String title;
  final String description;
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
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
  });

  /// Sort by severity (highest first), then by start time (soonest first)
  @override
  int compareTo(WarningItem other) {
    final severityCompare = other.severity.level.compareTo(severity.level);
    if (severityCompare != 0) return severityCompare;
    if (startTime != null && other.startTime != null) {
      return startTime!.compareTo(other.startTime!);
    }
    return 0;
  }

  /// Creates from DWD warning
  factory WarningItem.fromDWD(DwdWarningDto w) => WarningItem(
        source: 'DWD',
        severity: WarningSeverity.fromLevel(w.level),
        category: WarningCategory.fromType('weather', w.event),
        title: w.headline.isNotEmpty ? w.headline : w.event,
        description: w.effectiveDescription,
        startTime: w.start > 0 ? DateTime.fromMillisecondsSinceEpoch(w.start) : null,
        endTime: w.end > 0 ? DateTime.fromMillisecondsSinceEpoch(w.end) : null,
      );

  /// Creates from NINA warning
  factory WarningItem.fromNINA(NinaWarningDto w) => WarningItem(
        source: 'NINA',
        severity: _severityFromString(w.severity),
        category: WarningCategory.fromType(w.type, w.title),
        title: w.title,
        description: w.description,
        startTime: w.sent.isNotEmpty ? DateTime.tryParse(w.sent) : null,
      );

  /// Creates from OpenMeteo Air Quality data
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
          startTime: DateTime.now(),
      );
  }

  /// Creates from OpenMeteo Flood/River data
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
         startTime: DateTime.now(),
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

  // --- Display helpers ---

  /// Whether warning is currently active
  bool get isActive {
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    return true;
  }

  /// Whether warning has ended
  bool get hasEnded => endTime != null && DateTime.now().isAfter(endTime!);

  /// Formatted time range for display
  String get formattedTimeRange => formatTimeRange(startTime, endTime);

  /// Relative time description (e.g. "in 2 hours", "started 30 min ago")
  String get relativeTimeInfo {
    final now = DateTime.now();

    if (startTime != null && now.isBefore(startTime!)) {
      final diff = startTime!.difference(now);
      if (diff.inDays > 0) return 'Starts in ${diff.inDays}d';
      if (diff.inHours > 0) return 'Starts in ${diff.inHours}h';
      return 'Starts in ${diff.inMinutes}min';
    }

    if (endTime != null) {
      if (now.isAfter(endTime!)) return 'Ended';
      final diff = endTime!.difference(now);
      if (diff.inDays > 0) return 'Ends in ${diff.inDays}d';
      if (diff.inHours > 0) return 'Ends in ${diff.inHours}h';
      return 'Ends in ${diff.inMinutes}min';
    }

    return 'Active now';
  }
}
