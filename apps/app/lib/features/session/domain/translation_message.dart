import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_message.freezed.dart';
part 'translation_message.g.dart';

@freezed
abstract class TranslationMessage with _$TranslationMessage {
  const factory TranslationMessage({
    required String text,
    @JsonKey(name: 'source_language', defaultValue: '')
    required String sourceLanguage,
    @JsonKey(name: 'target_language', defaultValue: '')
    required String targetLanguage,
    @JsonKey(name: 'translated_at') required DateTime translatedAt,
  }) = _TranslationMessage;

  factory TranslationMessage.fromJson(Map<String, dynamic> json) =>
      _$TranslationMessageFromJson(json);
}