import 'dart:async';
import 'dart:convert';

import 'package:app/config/env_config.dart';
import 'package:app/core/logger/app_logger.dart';
import 'package:app/features/session/domain/websocket_event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketClient {
  final AppLogger _logger;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  ChatWebSocketClient(this._logger);

  Stream<WebSocketEvent> get events => _eventController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String roomId, {String? profileId, String? nick}) async {
    await disconnect();

    final urlString = '${EnvConfig.current.wsBaseUrl}?room=$roomId';
    _logger.i('Connecting WebSocket to $urlString', module: 'ChatWebSocket');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(urlString));
      _eventController.add(const WebSocketConnectionOpened());

      _subscription = _channel!.stream.listen(
        (rawMessage) {
          if (rawMessage is String) {
            _logger.t('Received WS raw message: $rawMessage', module: 'ChatWebSocket');
            _eventController.add(WebSocketMessageReceived(rawMessage));
          }
        },
        onDone: () {
          _logger.w('WebSocket closed by server', module: 'ChatWebSocket');
          _eventController.add(const WebSocketConnectionClosed());
        },
        onError: (error, stackTrace) {
          final actualError = error as Object;
          final actualStack = stackTrace is StackTrace ? stackTrace : null;
          _logger.e('WebSocket error', module: 'ChatWebSocket', error: actualError, stackTrace: actualStack);
          _eventController.add(WebSocketConnectionError(actualError, actualStack));
        },
      );

      if (profileId != null || nick != null) {
        final authPayload = {
          'type': 'join',
          'payload': {
            'profile_id': profileId,
            'nick': nick,
          },
        };
        send(authPayload);
      }
    } catch (e, st) {
      _logger.e('Failed to connect WebSocket', module: 'ChatWebSocket', error: e, stackTrace: st as StackTrace?);
      _eventController.add(WebSocketConnectionError(e, st as StackTrace?));
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel == null) {
      _logger.w('Cannot send WS data, channel not connected', module: 'ChatWebSocket');
      return;
    }

    try {
      final payload = jsonEncode(data);
      _logger.t('Sending WS payload: $payload', module: 'ChatWebSocket');
      _channel!.sink.add(payload);
    } catch (e, st) {
      _logger.e('Failed to send WS payload', module: 'ChatWebSocket', error: e, stackTrace: st as StackTrace?);
      _eventController.add(WebSocketConnectionError(e, st as StackTrace?));
    }
  }

  Future<void> disconnect() async {
    _logger.i('Disconnecting WebSocket client', module: 'ChatWebSocket');
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _eventController.add(const WebSocketConnectionClosed());
  }
}
