import 'package:app/features/session/domain/message_status.dart';
import 'package:app/features/session/domain/message_type.dart';
import 'package:app/features/session/domain/translation_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageSource { me, other, system }

@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._(); // Wymagane dla własnych getterów/metod w klasie Freezed

  const factory ChatMessage({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(name: 'room_id', defaultValue: '') @Default('') String roomId,
    @JsonKey(name: 'author_id', defaultValue: '') @Default('') String authorId,
    @JsonKey(name: 'author_nick', defaultValue: '')
    @Default('')
    String authorNick,
    required String text,
    TranslationMessage? translation,
    @Default(MessageType.text) MessageType type,
    @Default(MessageStatus.sent) MessageStatus status,
    required DateTime timestamp,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(MessageSource.other)
    MessageSource source,
  }) = _ChatMessage;

  /// Getter ułatwiający bezpośredni dostęp do tekstu tłumaczenia w UI
  String? get translatedText => translation?.text;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// Fabryka pomocnicza do rozwiązywania źródła wiadomości na podstawie ID użytkownika
  factory ChatMessage.fromPayload(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final message = ChatMessage.fromJson(json);
    
    MessageSource resolvedSource = MessageSource.other;
    if (message.type == MessageType.system) {
      resolvedSource = MessageSource.system;
    } else if (currentUserId != null && message.authorId == currentUserId) {
      resolvedSource = MessageSource.me;
    }

    return message.copyWith(source: resolvedSource);
  }
}