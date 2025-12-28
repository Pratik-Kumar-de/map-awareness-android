import 'package:clock/clock.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:map_awareness/utils/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'geo_coordinate.dart';

part 'roadwork.g.dart';

/// Data Transfer Object for roadworks from autobahn API.
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

  /// Joins multiline description list into single text block.
  String get descriptionText => description?.join('\n') ?? '';

  String get formattedTimeRange => formatTimeRange(
    startTimestamp != null ? DateTime.tryParse(startTimestamp!) : null, 
    null
  );

  double? get latitude => coordinate?.latitude;
  double? get longitude => coordinate?.longitude;

  String? get length => Helpers.findByPrefix(description, 'Length');
  String? get speedLimit => Helpers.findByPrefix(description, 'Maximum Speed');
  String? get maxWidth => Helpers.findByPrefix(description, 'Maximum Width');

  /// Formats the raw display type enum into readable text.
  String get typeLabel => switch (displayType) {
    'SHORT_TERM_ROADWORKS' => 'Short Term',
    'LONG_TERM_ROADWORKS' => 'Long Term',
    _ => displayType.replaceAll('_', ' '),
  };

  bool get isShortTerm => displayType == 'SHORT_TERM_ROADWORKS';

  String get timeInfo {
     if (startTimestamp == null || startTimestamp!.isEmpty) return 'Ongoing';
    final dt = DateTime.tryParse(startTimestamp!);
    if (dt == null || dt.isBefore(clock.now())) return 'Ongoing';
    return timeago.format(dt, allowFromNow: true);
  }
}

