import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../models/user.dart';
import '../models/message.dart';
import '../models/attachment.dart';

class SocketService {
  io_client.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String baseUrl,
    required User currentUser,
    Function(Message)? onNewMessage,
    Function(String channelId, String userId, String username, bool isTyping)? onTyping,
    Function(String channelId, String messageId, List reactions)? onReactionUpdated,
    Function(String channelId, String messageId, bool isPinned)? onPinToggled,
    Function(String channelId, String messageId)? onMessageDeleted,
    Function(String userId, User user, bool online)? onUserPresence,
  }) {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
    }

    _socket = io_client.io(
      baseUrl,
      io_client.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'Bypass-Tunnel-Reminder': 'true'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('user_connected', currentUser.toJson());
    });

    _socket!.on('new_message', (data) {
      if (data is Map) {
        final msg = Message.fromJson(Map<String, dynamic>.from(data));
        onNewMessage?.call(msg);
      }
    });

    _socket!.on('user_typing', (data) {
      if (data is Map) {
        final channelId = data['channelId']?.toString() ?? '';
        final username = data['username']?.toString() ?? 'User';
        final userId = data['userId']?.toString() ?? '';
        final isTyping = data['isTyping'] == true;
        onTyping?.call(channelId, userId, username, isTyping);
      }
    });

    _socket!.on('reaction_updated', (data) {
      if (data is Map) {
        final messageId = data['messageId']?.toString() ?? '';
        final channelId = data['channelId']?.toString() ?? '';
        final List rxList = data['reactions'] ?? [];
        onReactionUpdated?.call(channelId, messageId, rxList);
      }
    });

    _socket!.on('pin_toggled', (data) {
      if (data is Map) {
        final messageId = data['messageId']?.toString() ?? '';
        final channelId = data['channelId']?.toString() ?? '';
        final isPinned = data['isPinned'] == 1 || data['isPinned'] == true;
        onPinToggled?.call(channelId, messageId, isPinned);
      }
    });

    _socket!.on('message_deleted', (data) {
      if (data is Map) {
        final messageId = data['messageId']?.toString() ?? '';
        final channelId = data['channelId']?.toString() ?? '';
        onMessageDeleted?.call(channelId, messageId);
      }
    });

    _socket!.on('user_presence', (data) {
      if (data is Map) {
        final userId = data['userId']?.toString() ?? '';
        final online = data['online'] == true;
        final userMap = data['user'];
        if (userMap is Map) {
          final user = User.fromJson(Map<String, dynamic>.from(userMap));
          onUserPresence?.call(userId, user, online);
        }
      }
    });
  }

  void joinChannel(String channelId) {
    _socket?.emit('join_channel', {'channelId': channelId});
  }

  void leaveChannel(String channelId) {
    _socket?.emit('leave_channel', {'channelId': channelId});
  }

  void sendMessage({
    required String channelId,
    required String senderId,
    required String text,
    String? replyToId,
    List<Attachment> attachments = const [],
  }) {
    final attsJson = attachments.map((a) => a.toJson()).toList();
    _socket?.emit('send_message', {
      'channelId': channelId,
      'senderId': senderId,
      'text': text,
      'replyToId': replyToId,
      'attachments': attsJson,
    });
  }

  void sendTyping(String channelId, bool isTyping) {
    _socket?.emit('typing', {
      'channelId': channelId,
      'isTyping': isTyping,
    });
  }

  void toggleReaction(String channelId, String messageId, String userId, String emoji) {
    _socket?.emit('toggle_reaction', {
      'channelId': channelId,
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
    });
  }

  void togglePin(String channelId, String messageId) {
    _socket?.emit('toggle_pin', {
      'channelId': channelId,
      'messageId': messageId,
    });
  }

  void deleteMessage(String channelId, String messageId, String userId) {
    _socket?.emit('delete_message', {
      'channelId': channelId,
      'messageId': messageId,
      'userId': userId,
    });
  }

  void updateStatus({
    required String username,
    required String status,
    required String customStatus,
    required String avatar,
  }) {
    _socket?.emit('update_status', {
      'username': username,
      'status': status,
      'custom_status': customStatus,
      'avatar': avatar,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
