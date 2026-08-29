class Channel {
  final String id;
  final String name;
  final String description;
  final bool isDirect;
  final String icon;
  final String? otherUserId;
  final String? otherUsername;
  final String? otherAvatar;
  final String? otherStatus;
  final String? otherCustomStatus;
  final String? lastMessageText;
  final String? lastMessageTime;

  Channel({
    required this.id,
    required this.name,
    this.description = '',
    this.isDirect = false,
    this.icon = '👥',
    this.otherUserId,
    this.otherUsername,
    this.otherAvatar,
    this.otherStatus,
    this.otherCustomStatus,
    this.lastMessageText,
    this.lastMessageTime,
  });

  String get displayName => isDirect ? (otherUsername ?? name) : name;
  String get displayAvatar => otherAvatar ?? '';

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id']?.toString() ?? '',
      name: json['display_name']?.toString() ?? json['name']?.toString() ?? 'Conversation',
      description: json['description']?.toString() ?? '',
      isDirect: json['is_direct'] == 1 || json['is_direct'] == true,
      icon: json['icon']?.toString() ?? (json['is_direct'] == 1 ? '💬' : '👥'),
      otherUserId: json['other_user_id']?.toString(),
      otherUsername: json['other_username']?.toString() ?? json['display_name']?.toString(),
      otherAvatar: json['other_avatar']?.toString() ?? json['display_avatar']?.toString(),
      otherStatus: json['other_status']?.toString(),
      otherCustomStatus: json['other_custom_status']?.toString(),
      lastMessageText: json['last_message_text']?.toString(),
      lastMessageTime: json['last_message_time']?.toString(),
    );
  }
}
