class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<String> participantIds;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.participantIds = const [],
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? participantIds,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'participant_ids': participantIds,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      participantIds: (json['participant_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
