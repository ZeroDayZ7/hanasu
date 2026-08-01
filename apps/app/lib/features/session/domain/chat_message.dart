import 'package:app/features/session/domain/message_status.dart';
import 'package:app/features/session/domain/message_type.dart';
import 'package:app/features/session/domain/translation_message.dart';

enum MessageSource { me, other, system }

class ChatMessage {
  final String id;
  final String roomId;
  final String authorId;
  final String authorNick;
  final String text;
  final TranslationMessage? translation;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final MessageSource source; // Wymagane przez UI/Controller

  const ChatMessage({
    required this.id,
    this.roomId = '',
    this.authorId = '',
    this.authorNick = '',
    required this.text,
    this.translation,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.source = MessageSource.other, // Domyślnie nadawcą jest inny użytkownik
  });

  // Getter ułatwiający bezpośredni dostęp do tekstu tłumaczenia w UI
  String? get translatedText => translation?.text;

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? authorId,
    String? authorNick,
    String? text,
    TranslationMessage? translation,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    MessageSource? source,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      authorId: authorId ?? this.authorId,
      authorNick: authorNick ?? this.authorNick,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'author_id': authorId,
      'author_nick': authorNick,
      'text': text,
      'translation': translation?.toJson(),
      'type': type.toShortString(),
      'status': status.toShortString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId, // Opcjonalny ID użytkownika do ustalenia źródła
  }) {
    final authorId = json['author_id'] as String? ?? '';

    // Automatyczne ustalanie źródła wiadomości na podstawie ID
    MessageSource resolvedSource = MessageSource.other;
    if (json['type'] == 'system') {
      resolvedSource = MessageSource.system;
    } else if (currentUserId != null && authorId == currentUserId) {
      resolvedSource = MessageSource.me;
    }

    return ChatMessage(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      authorId: authorId,
      authorNick: json['author_nick'] as String? ?? '',
      text: json['text'] as String? ?? '',
      translation: json['translation'] != null
          ? TranslationMessage.fromJson(
              Map<String, dynamic>.from(json['translation'] as Map),
            )
          : null,
      type: MessageTypeExtension.fromString(json['type'] as String? ?? 'text'),
      status: MessageStatusExtension.fromString(
        json['status'] as String? ?? 'sent',
      ),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      source: resolvedSource,
    );
  }
}
