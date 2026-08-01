class UserProfile {
  final String id;
  final String nick;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.nick,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? nick,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nick: nick ?? this.nick,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nick': nick,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      nick: json['nick'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
