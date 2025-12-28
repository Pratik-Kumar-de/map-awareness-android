import 'package:json_annotation/json_annotation.dart';

part 'nina_warning.g.dart';

/// Data Transfer Object for NINA (Emergency Information) warnings.
@JsonSerializable(createToJson: false)
class NinaWarningDto {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'severity')
  final String severity;

  @JsonKey(name: 'i18nTitle')
  final Map<String, String>? i18nTitle;

  @JsonKey(name: 'payload')
  final Map<String, dynamic>? payload;

  @JsonKey(name: 'sent')
  final String sent;

  NinaWarningDto({
    required this.id,
    required this.type,
    required this.severity,
    this.i18nTitle,
    this.payload,
    required this.sent,
  });
  
  /// Gets the localized title, defaulting to English or payload headline.
  String get title => i18nTitle?['en'] ?? payload?['headline'] ?? '';
  
  /// Gets the description from payload or localized title as fallback.
  String get description => payload?['description'] ?? i18nTitle?['en'] ?? '';

  factory NinaWarningDto.fromJson(Map<String, dynamic> json) => _$NinaWarningDtoFromJson(json);
}
