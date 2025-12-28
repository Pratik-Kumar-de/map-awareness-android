import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'geo_coordinate.dart';

part 'roadwork.g.dart';

@JsonSerializable(createToJson: false)
class RoadworkDto {
  @JsonKey(defaultValue: '') final String identifier;
  @JsonKey(defaultValue: '') final String title;
  @JsonKey(defaultValue: '') final String subtitle;
  @JsonKey(defaultValue: '') final String icon;
  @JsonKey(name: 'display_type', defaultValue: '') final String displayType;
  @JsonKey(defaultValue: '') final String? startTimestamp;
  @JsonKey(fromJson: safeBool) final bool isBlocked;
  @JsonKey(name: 'future', fromJson: safeBool) final bool isFuture;
  final List<String>? description;
  final GeoCoordinate? coordinate;

  RoadworkDto({
    required this.identifier, required this.title,
    required this.subtitle, required this.icon, required this.displayType,
    this.startTimestamp, this.isBlocked = false, this.isFuture = false,
    this.description, this.coordinate,
  });

  factory RoadworkDto.fromJson(Map<String, dynamic> json) => _$RoadworkDtoFromJson(json);

  String get descriptionText => description?.join('\n') ?? '';

  String get formattedTimeRange => formatTimeRange(
    startTimestamp != null ? DateTime.tryParse(startTimestamp!) : null, 
    null
  );

  double? get latitude => coordinate?.latitude;
  double? get longitude => coordinate?.longitude;

  // Use shared helper for parsing description fields
  String? get length => findByPrefix(description, 'Length');
  String? get speedLimit => findByPrefix(description, 'Maximum Speed');
  String? get maxWidth => findByPrefix(description, 'Maximum Width');

  String get typeLabel => switch (displayType) {
    'SHORT_TERM_ROADWORKS' => 'Short Term',
    'LONG_TERM_ROADWORKS' => 'Long Term',
    _ => displayType.replaceAll('_', ' '),
  };

  bool get isShortTerm => displayType == 'SHORT_TERM_ROADWORKS';

  String get timeInfo {
    if (startTimestamp == null || startTimestamp!.isEmpty) return 'Ongoing';
    final dt = DateTime.tryParse(startTimestamp!);
    if (dt == null || dt.isBefore(DateTime.now())) return 'Ongoing';
    final d = dt.difference(DateTime.now()).inDays;
    return d > 7 ? DateFormat('dd.MM').format(dt) : d > 0 ? 'In ${d}d' : 'Soon';
  }

  String get relativeTimeInfo => timeInfo;

  bool isRoadworkInSegment(double minLat, double maxLat, double minLng, double maxLng) {
    return isCoordinateInBounds(coordinate?.latitude, coordinate?.longitude, minLat, maxLat, minLng, maxLng);
  }
}

