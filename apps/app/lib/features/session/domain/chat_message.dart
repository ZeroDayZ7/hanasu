enum MessageSource { me, peer, system }

class ChatMessage {
  final String id;
  final String text;
  final String? translatedText;
  final MessageSource source;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    this.translatedText,
    required this.source,
    required this.timestamp,
  });
}
