import 'package:json_annotation/json_annotation.dart';

part 'dwd_warning.g.dart';

/// Data Transfer Object for DWD (German Weather Service) warnings.
@JsonSerializable(createToJson: false)
class DwdWarningDto {
  @JsonKey(name: 'type', defaultValue: 0)
  final int type;

  @JsonKey(name: 'level', defaultValue: 1)
  final int level;

  @JsonKey(name: 'event', defaultValue: '')
  final String event;

  @JsonKey(name: 'headLine', defaultValue: '')
  final String headline;

  @JsonKey(name: 'descriptionText')
  final String? descriptionText;

  @JsonKey(name: 'description')
  final String? description;

    @JsonKey(name: 'instruction')
    final String? instruction;

    @JsonKey(name: 'start', defaultValue: 0)
    final int start;

    @JsonKey(name: 'end', defaultValue: 0)
    final int end;

  DwdWarningDto({
    required this.type,
    required this.level,
    required this.event,
    required this.headline,
    this.descriptionText,
    this.description,
    this.instruction,
    required this.start,
    required this.end,
  });

  /// Returns the most detailed description available (descriptionText > description).
  String get effectiveDescription => descriptionText ?? description ?? '';

  factory DwdWarningDto.fromJson(Map<String, dynamic> json) => _$DwdWarningDtoFromJson(json);
}
