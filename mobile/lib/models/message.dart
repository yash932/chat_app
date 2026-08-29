import 'attachment.dart';
import 'reaction.dart';

class Message {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String senderStatus;
  final String text;
  final String? replyToId;
  final String? replyToSender;
  final String? replyToText;
  final bool isEdited;
  final bool isPinned;
  final DateTime createdAt;
  final List<Attachment> attachments;
  final List<Reaction> reactions;

  Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    this.senderStatus = 'offline',
    required this.text,
    this.replyToId,
    this.replyToSender,
    this.replyToText,
    this.isEdited = false,
    this.isPinned = false,
    required this.createdAt,
    this.attachments = const [],
    this.reactions = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    List<Attachment> attList = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      attList = (json['attachments'] as List)
          .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<Reaction> rxList = [];
    if (json['reactions'] != null && json['reactions'] is List) {
      rxList = (json['reactions'] as List)
          .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    String? replySender;
    String? replyText;
    if (json['replyTo'] != null && json['replyTo'] is Map) {
      replySender = json['replyTo']['sender_name']?.toString();
      replyText = json['replyTo']['text']?.toString();
    }

    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Message(
      id: json['id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      senderAvatar: json['sender_avatar']?.toString() ?? '',
      senderStatus: json['sender_status']?.toString() ?? 'offline',
      text: json['text']?.toString() ?? '',
      replyToId: json['reply_to_id']?.toString(),
      replyToSender: replySender,
      replyToText: replyText,
      isEdited: json['is_edited'] == 1 || json['is_edited'] == true,
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      createdAt: parsedDate,
      attachments: attList,
      reactions: rxList,
    );
  }

  Message copyWith({
    bool? isPinned,
    bool? isEdited,
    List<Reaction>? reactions,
  }) {
    return Message(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderStatus: senderStatus,
      text: text,
      replyToId: replyToId,
      replyToSender: replyToSender,
      replyToText: replyToText,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      attachments: attachments,
      reactions: reactions ?? this.reactions,
    );
  }

  Message copyWithReactions(List newReactions) {
    final List<Reaction> rxList = newReactions
        .map((r) => r is Reaction ? r : Reaction.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    return copyWith(reactions: rxList);
  }
}
