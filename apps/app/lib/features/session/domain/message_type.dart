enum MessageType {
  text,
  translation,
  audio,
  system,
}

extension MessageTypeExtension on MessageType {
  String toShortString() {
    return toString().split('.').last;
  }

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.toShortString() == value,
      orElse: () => MessageType.text,
    );
  }
}
