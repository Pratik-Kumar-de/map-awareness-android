import 'package:intl/intl.dart';
import 'package:map_awareness/APIs/dwd_api.dart';
import 'package:map_awareness/APIs/nina_api.dart';

/// Warning severity levels with display helpers
enum WarningSeverity {
  minor(1, 'Minor', 'Low risk'),
  moderate(2, 'Moderate', 'Be prepared'),
  severe(3, 'Severe', 'Take action'),
  extreme(4, 'Extreme', 'Immediate danger');

  final int level;
  final String label;
  final String hint;
  const WarningSeverity(this.level, this.label, this.hint);

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
    if (lower.contains('flood') || lower.contains('wasser') || lower.contains('hochwasser')) {
      return flood;
    }
    if (lower.contains('fire') || lower.contains('brand') || lower.contains('feuer')) {
      return fire;
    }
    if (lower.contains('health') || lower.contains('gesundheit') || lower.contains('corona')) {
      return health;
    }
    if (lower.contains('civil') || lower.contains('bevölkerung') || lower.contains('warnung')) {
      return civil;
    }
    if (lower.contains('wetter') || lower.contains('weather') || lower.contains('wind') ||
        lower.contains('storm') || lower.contains('gewitter') || lower.contains('schnee') ||
        lower.contains('frost') || lower.contains('hitze') || lower.contains('nebel')) {
      return weather;
    }
    if (lower.contains('air') || lower.contains('luft') || lower.contains('quality') || lower.contains('environment')) {
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
  final String region;
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
    this.region = '',
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
  factory WarningItem.fromDWD(DWDWarning w) => WarningItem(
    source: 'DWD',
    severity: WarningSeverity.fromLevel(w.level),
    category: WarningCategory.fromType('weather', w.event),
    title: w.headline.isNotEmpty ? w.headline : w.event,
    description: w.description,
    startTime: w.start > 0 ? DateTime.fromMillisecondsSinceEpoch(w.start) : null,
    endTime: w.end > 0 ? DateTime.fromMillisecondsSinceEpoch(w.end) : null,
  );

  /// Creates from NINA warning
  factory WarningItem.fromNINA(NINAWarning w) => WarningItem(
    source: 'NINA',
    severity: _severityFromString(w.severity),
    category: WarningCategory.fromType(w.type, w.title),
    title: w.title,
    description: w.description,
    startTime: w.sent.isNotEmpty ? DateTime.tryParse(w.sent) : null,
  );

  /// Creates from OpenMeteo Air Quality data
  static WarningItem? fromOpenMeteoAirQuality(Map<String, dynamic> data) {
      final aqi = data['us_aqi'] as num?;
      if (aqi == null) return null;
      
      WarningSeverity sev = WarningSeverity.minor;
      String desc = 'Good air quality';
      if (aqi > 50) { sev = WarningSeverity.moderate; desc = 'Moderate air quality'; }
      if (aqi > 100) { sev = WarningSeverity.severe; desc = 'Unhealthy for sensitive groups'; }
      if (aqi > 150) { sev = WarningSeverity.extreme; desc = 'Unhealthy air quality'; }
      if (aqi > 200) { sev = WarningSeverity.extreme; desc = 'Very Unhealthy air quality'; }

      return WarningItem(
          source: 'OpenMeteo',
          severity: sev,
          category: WarningCategory.environment,
          title: 'Air Quality Index: $aqi',
          description: '$desc. PM10: ${data['pm10']} µg/m³, PM2.5: ${data['pm2_5']} µg/m³',
          startTime: DateTime.now(), // Current
      );
  }

  /// Creates from OpenMeteo Flood/River data
  static WarningItem? fromOpenMeteoFlood(Map<String, dynamic> data) {
     final discharge = data['river_discharge'] as num?;
     final unit = data['unit'] ?? 'm³/s';
     
     if (discharge == null) return null;

     // Simple heuristic as we don't have historical averages for every point
     // Just informing the user about the discharge
     return WarningItem(
         source: 'OpenMeteo',
         severity: WarningSeverity.minor, // purely informational usually
         category: WarningCategory.flood,
         title: 'River Discharge',
         description: 'Current discharge: $discharge $unit',
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
  String get formattedTimeRange {
    final dateFormat = DateFormat('dd.MM, HH:mm');
    final timeFormat = DateFormat('HH:mm');

    if (startTime == null && endTime == null) return 'Ongoing';

    if (startTime != null && endTime != null) {
      if (startTime!.day == endTime!.day && startTime!.month == endTime!.month) {
        return '${dateFormat.format(startTime!)} - ${timeFormat.format(endTime!)}';
      }
      return '${dateFormat.format(startTime!)} - ${dateFormat.format(endTime!)}';
    }
    if (startTime != null) return 'From ${dateFormat.format(startTime!)}';
    return 'Until ${dateFormat.format(endTime!)}';
  }

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
