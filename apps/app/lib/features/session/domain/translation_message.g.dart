// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TranslationMessage _$TranslationMessageFromJson(Map<String, dynamic> json) =>
    _TranslationMessage(
      text: json['text'] as String,
      sourceLanguage: json['source_language'] as String? ?? '',
      targetLanguage: json['target_language'] as String? ?? '',
      translatedAt: DateTime.parse(json['translated_at'] as String),
    );

Map<String, dynamic> _$TranslationMessageToJson(_TranslationMessage instance) =>
    <String, dynamic>{
      'text': instance.text,
      'source_language': instance.sourceLanguage,
      'target_language': instance.targetLanguage,
      'translated_at': instance.translatedAt.toIso8601String(),
    };
