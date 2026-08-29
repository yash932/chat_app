class Reaction {
  final String emoji;
  final String userId;
  final String? username;

  Reaction({
    required this.emoji,
    required this.userId,
    this.username,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      emoji: json['emoji']?.toString() ?? '❤️',
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'user_id': userId,
      'username': username,
    };
  }
}
