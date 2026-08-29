import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/channel.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  List<Channel> _conversations = [];
  List<User> _allUsers = [];
  Channel? _currentChannel;
  List<Message> _messages = [];
  final Map<String, String> _typingUsers = {};
  Message? _replyingToMessage;
  bool _isLoadingMessages = false;
  String _themeMode = 'light';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<Channel> get conversations => _conversations;
  List<Channel> get directMessages => _conversations.where((c) => c.isDirect).toList();
  List<Channel> get groups => _conversations.where((c) => !c.isDirect).toList();
  List<User> get allUsers => _allUsers;
  List<User> get activeUsers => _allUsers.where((u) => u.id != _currentUser?.id).toList();
  Channel? get currentChannel => _currentChannel;
  List<Message> get messages => _messages;
  Map<String, String> get typingUsers => _typingUsers;
  Message? get replyingToMessage => _replyingToMessage;
  bool get isLoadingMessages => _isLoadingMessages;
  String get themeMode => _themeMode;

  final SocketService _socketService = SocketService();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString('pulse_theme') ?? 'light';
    final savedUrl = prefs.getString('pulse_server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      ApiService.setBaseUrl(savedUrl);
    }

    final userId = prefs.getString('pulse_user_id');
    final userName = prefs.getString('pulse_user_name');
    final userEmail = prefs.getString('pulse_user_email');
    final userAvatar = prefs.getString('pulse_user_avatar');
    final userStatus = prefs.getString('pulse_user_status') ?? 'online';
    final userCustomStatus = prefs.getString('pulse_user_custom_status') ?? '';

    if (userId != null && userName != null) {
      _currentUser = User(
        id: userId,
        username: userName,
        email: userEmail ?? '',
        avatar: userAvatar ?? 'https://api.dicebear.com/7.x/identicon/svg?seed=${Uri.encodeComponent(userName)}',
        status: userStatus,
        customStatus: userCustomStatus,
      );
      _isLoggedIn = true;
      _setupSocket();
      await refreshData();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final user = await ApiService.login(email, password);
    _currentUser = user;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pulse_user_id', user.id);
    await prefs.setString('pulse_user_name', user.username);
    await prefs.setString('pulse_user_email', user.email);
    await prefs.setString('pulse_user_avatar', user.avatar);
    await prefs.setString('pulse_user_status', user.status);
    await prefs.setString('pulse_user_custom_status', user.customStatus);

    _setupSocket();
    await refreshData();
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password) async {
    final user = await ApiService.signup(username, email, password);
    _currentUser = user;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pulse_user_id', user.id);
    await prefs.setString('pulse_user_name', user.username);
    await prefs.setString('pulse_user_email', user.email);
    await prefs.setString('pulse_user_avatar', user.avatar);
    await prefs.setString('pulse_user_status', user.status);
    await prefs.setString('pulse_user_custom_status', user.customStatus);

    _setupSocket();
    await refreshData();
    notifyListeners();
  }

  Future<void> logout() async {
    _socketService.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pulse_user_id');
    await prefs.remove('pulse_user_name');
    await prefs.remove('pulse_user_email');
    await prefs.remove('pulse_user_avatar');

    _currentUser = null;
    _isLoggedIn = false;
    _conversations.clear();
    _currentChannel = null;
    _messages.clear();
    notifyListeners();
  }

  void _setupSocket() {
    if (_currentUser == null) return;
    _socketService.connect(
      baseUrl: ApiService.baseUrl,
      currentUser: _currentUser!,
      onNewMessage: _handleNewMessage,
      onTyping: _handleTyping,
      onReactionUpdated: _handleReactionUpdated,
      onPinToggled: _handlePinToggled,
      onMessageDeleted: _handleMessageDeleted,
      onUserPresence: _handleUserPresence,
    );
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;
    final convos = await ApiService.getConversations(_currentUser!.id);
    final users = await ApiService.getAllUsers();
    _conversations = convos;
    _allUsers = users;

    if (_currentChannel != null) {
      final updated = _conversations.firstWhere(
        (c) => c.id == _currentChannel!.id,
        orElse: () => _currentChannel!,
      );
      _currentChannel = updated;
    }
    notifyListeners();
  }

  Future<void> selectChannel(Channel channel) async {
    if (_currentChannel?.id == channel.id) return;
    _currentChannel = channel;
    _replyingToMessage = null;
    _messages = [];
    _isLoadingMessages = true;
    notifyListeners();

    _socketService.joinChannel(channel.id);
    _messages = await ApiService.getChannelMessages(channel.id);
    _isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> startDirectMessage(String otherUserId) async {
    if (_currentUser == null) return;
    final dm = await ApiService.startDirectMessage(_currentUser!.id, otherUserId);
    if (dm != null) {
      await refreshData();
      final fresh = _conversations.firstWhere((c) => c.id == dm.id, orElse: () => dm);
      await selectChannel(fresh);
    }
  }

  Future<void> createGroup(String name, String description, List<String> memberIds) async {
    if (_currentUser == null) return;
    final grp = await ApiService.createGroup(name, description, '👥', memberIds, _currentUser!.id);
    if (grp != null) {
      await refreshData();
      final fresh = _conversations.firstWhere((c) => c.id == grp.id, orElse: () => grp);
      await selectChannel(fresh);
    }
  }

  void sendMessage(String text, {List<Attachment> attachments = const []}) {
    if (_currentChannel == null || _currentUser == null) return;
    if (text.trim().isEmpty && attachments.isEmpty) return;

    _socketService.sendMessage(
      channelId: _currentChannel!.id,
      senderId: _currentUser!.id,
      text: text.trim(),
      replyToId: _replyingToMessage?.id,
      attachments: attachments,
    );

    _replyingToMessage = null;
    notifyListeners();
  }

  void sendTyping(bool isTyping) {
    if (_currentChannel != null) {
      _socketService.sendTyping(_currentChannel!.id, isTyping);
    }
  }

  void toggleReaction(String messageId, String emoji) {
    if (_currentChannel == null || _currentUser == null) return;
    _socketService.toggleReaction(_currentChannel!.id, messageId, _currentUser!.id, emoji);
  }

  void togglePin(String messageId) {
    if (_currentChannel == null) return;
    _socketService.togglePin(_currentChannel!.id, messageId);
  }

  void deleteMessage(String messageId) {
    if (_currentChannel == null || _currentUser == null) return;
    _socketService.deleteMessage(_currentChannel!.id, messageId, _currentUser!.id);
  }

  void setReplyingTo(Message? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  Future<void> toggleTheme(String mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pulse_theme', mode);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String username,
    required String status,
    required String customStatus,
    required String avatar,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      username: username,
      status: status,
      customStatus: customStatus,
      avatar: avatar,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pulse_user_name', username);
    await prefs.setString('pulse_user_status', status);
    await prefs.setString('pulse_user_custom_status', customStatus);
    await prefs.setString('pulse_user_avatar', avatar);

    _socketService.updateStatus(
      username: username,
      status: status,
      customStatus: customStatus,
      avatar: avatar,
    );
    notifyListeners();
  }

  Future<void> updateServerUrl(String url) async {
    ApiService.setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pulse_server_url', url);
    _socketService.disconnect();
    _setupSocket();
    await refreshData();
  }

  void _handleNewMessage(Message msg) {
    if (_currentChannel != null && msg.channelId == _currentChannel!.id) {
      _messages.add(msg);
      notifyListeners();
    }
    // Update preview in conversation list
    refreshData();
  }

  void _handleTyping(String channelId, String userId, String username, bool isTyping) {
    if (_currentChannel != null && channelId == _currentChannel!.id) {
      if (isTyping) {
        _typingUsers[userId] = username;
      } else {
        _typingUsers.remove(userId);
      }
      notifyListeners();
    }
  }

  void _handleReactionUpdated(String channelId, String messageId, List reactions) {
    if (_currentChannel != null && channelId == _currentChannel!.id) {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWithReactions(reactions);
        notifyListeners();
      }
    }
  }

  void _handlePinToggled(String channelId, String messageId, bool isPinned) {
    if (_currentChannel != null && channelId == _currentChannel!.id) {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isPinned: isPinned);
        notifyListeners();
      }
    }
  }

  void _handleMessageDeleted(String channelId, String messageId) {
    if (_currentChannel != null && channelId == _currentChannel!.id) {
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    }
  }

  void _handleUserPresence(String userId, User user, bool online) {
    final idx = _allUsers.indexWhere((u) => u.id == userId);
    if (online) {
      if (idx != -1) {
        _allUsers[idx] = user;
      } else {
        _allUsers.add(user);
      }
    } else {
      if (idx != -1) {
        _allUsers[idx] = _allUsers[idx].copyWith(status: 'offline');
      }
    }
    notifyListeners();
  }
}
