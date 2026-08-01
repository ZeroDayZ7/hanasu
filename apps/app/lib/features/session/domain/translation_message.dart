class TranslationMessage {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime translatedAt;

  const TranslationMessage({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translatedAt,
  });

  TranslationMessage copyWith({
    String? text,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? translatedAt,
  }) {
    return TranslationMessage(
      text: text ?? this.text,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translatedAt: translatedAt ?? this.translatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'translated_at': translatedAt.toIso8601String(),
    };
  }

  factory TranslationMessage.fromJson(Map<String, dynamic> json) {
    return TranslationMessage(
      text: json['text'] as String? ?? '',
      sourceLanguage: json['source_language'] as String? ?? '',
      targetLanguage: json['target_language'] as String? ?? '',
      translatedAt: DateTime.tryParse(json['translated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
