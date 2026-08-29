class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final String status;
  final String customStatus;
  final String? lastSeen;

  User({
    required this.id,
    required this.username,
    this.email = '',
    required this.avatar,
    this.status = 'online',
    this.customStatus = '',
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Anonymous',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      status: json['status']?.toString() ?? 'offline',
      customStatus: json['custom_status']?.toString() ?? '',
      lastSeen: json['last_seen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'status': status,
      'custom_status': customStatus,
      'last_seen': lastSeen,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatar,
    String? status,
    String? customStatus,
    String? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      customStatus: customStatus ?? this.customStatus,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
