import 'package:app/core/logger/app_logger.dart';
import 'package:app/features/session/data/chat_websocket_client.dart';
import 'package:app/features/session/domain/translation_message.dart';
import 'package:app/features/session/domain/user_profile.dart';
import 'package:app/features/session/domain/websocket_event.dart';

class SessionRepository {
  final ChatWebSocketClient _client;
  final AppLogger _logger;

  SessionRepository(this._client, this._logger);

  Stream<WebSocketEvent> get events => _client.events;

  Future<void> connect({
    required String roomId,
    required UserProfile profile,
  }) async {
    _logger.i('Opening chat session for room $roomId', module: 'SessionRepository');
    await _client.connect(roomId, profileId: profile.id, nick: profile.nick);
  }

  void sendTextMessage({
    required String roomId,
    required UserProfile author,
    required String text,
  }) {
    final message = {
      'type': 'message',
      'payload': {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'room_id': roomId,
        'author_id': author.id,
        'author_nick': author.nick,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'text',
        'status': 'sending',
      },
    };
    _logger.d('Sending text message to room $roomId', module: 'SessionRepository');
    _client.send(message);
  }

  void sendTranslationRequest({
    required String roomId,
    required UserProfile author,
    required String text,
    required String targetLanguage,
  }) {
    final payload = {
      'type': 'translation_request',
      'payload': {
        'room_id': roomId,
        'author_id': author.id,
        'author_nick': author.nick,
        'text': text,
        'target_language': targetLanguage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    _logger.d('Sending translation request for room $roomId', module: 'SessionRepository');
    _client.send(payload);
  }

  void sendTranslationResponse({
    required String roomId,
    required UserProfile author,
    required String text,
    required TranslationMessage translation,
  }) {
    final payload = {
      'type': 'translation_response',
      'payload': {
        'room_id': roomId,
        'author_id': author.id,
        'author_nick': author.nick,
        'text': text,
        'translation': translation.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    _logger.d('Sending translation response for room $roomId', module: 'SessionRepository');
    _client.send(payload);
  }

  Future<void> disconnect() async {
    _logger.i('Closing chat session', module: 'SessionRepository');
    await _client.disconnect();
  }
}
