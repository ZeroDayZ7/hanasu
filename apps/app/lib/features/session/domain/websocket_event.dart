abstract class WebSocketEvent {
  const WebSocketEvent();
}

class WebSocketConnectionOpened extends WebSocketEvent {
  const WebSocketConnectionOpened();
}

class WebSocketConnectionClosed extends WebSocketEvent {
  final int? code;
  final String? reason;

  const WebSocketConnectionClosed({this.code, this.reason});
}

class WebSocketConnectionError extends WebSocketEvent {
  final Object error;
  final StackTrace? stackTrace;

  const WebSocketConnectionError(this.error, [this.stackTrace]);
}

class WebSocketMessageReceived extends WebSocketEvent {
  final String raw;

  const WebSocketMessageReceived(this.raw);
}

class WebSocketRoomEvent extends WebSocketEvent {
  final String roomId;
  final String eventType;
  final Map<String, dynamic> payload;

  const WebSocketRoomEvent({
    required this.roomId,
    required this.eventType,
    required this.payload,
  });
}
