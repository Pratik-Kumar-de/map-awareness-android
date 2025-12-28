import 'package:json_annotation/json_annotation.dart';

part 'nina_warning.g.dart';

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
  
  String get title => i18nTitle?['en'] ?? payload?['headline'] ?? '';
  String get description => payload?['description'] ?? i18nTitle?['en'] ?? '';

  factory NinaWarningDto.fromJson(Map<String, dynamic> json) => _$NinaWarningDtoFromJson(json);
}
