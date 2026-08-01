enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  received,
  failed,
}

extension MessageStatusExtension on MessageStatus {
  String toShortString() {
    return toString().split('.').last;
  }

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.toShortString() == value,
      orElse: () => MessageStatus.sent,
    );
  }
}
