import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/status_dot.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class _Conversation {
  final String name, preview, time, initials;
  final Color bg, fg;
  final int unread;
  final bool online;
  const _Conversation(this.name, this.preview, this.time, this.initials, this.bg, this.fg,
      {this.unread = 0, this.online = false});
}

const _conversations = [
  _Conversation('Riya Mehta', 'Sounds good, see you then!', '09:41', 'RM', Color(0xFFF1E4D8), Color(0xFF8A5A2B), unread: 2, online: true),
  _Conversation('Dev Sharma', 'Sent the files over, check inbox', '09:12', 'DS', Color(0xFFDCEFE9), Color(0xFF2E6B5E), online: true),
  _Conversation('Team · Work', 'Aria: standup moved to 11am', 'Yesterday', 'TW', Color(0xFFE7E1F5), Color(0xFF5B4B8A), unread: 5),
  _Conversation('Aditi Kapoor', 'Haha yes exactly 😄', 'Yesterday', 'AK', Color(0xFFF5DDE5), Color(0xFF8A2B4A)),
  _Conversation('Nikhil Patwari', 'You: Thanks, appreciate it', 'Mon', 'NP', Color(0xFFDCEBF5), Color(0xFF2B6B8A)),
  _Conversation('Sara Grover', 'Can we push the call to 3?', 'Mon', 'SG', Color(0xFFF1EBDC), Color(0xFF7A6B2B), online: true),
];

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: const Avatar(initials: 'JL', size: AvatarSize.sm, status: PresenceStatus.online),
          ),
        ),
        title: Text('Chats', style: AppTypography.title(c.ink)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: c.inkTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search conversations',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: AppTypography.body(c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, i) {
                final conv = _conversations[i];
                return ConversationTile(
                  name: conv.name,
                  preview: conv.preview,
                  time: conv.time,
                  initials: conv.initials,
                  avatarBg: conv.bg,
                  avatarFg: conv.fg,
                  unreadCount: conv.unread,
                  online: conv.online,
                  selected: i == 0,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(name: conv.name, initials: conv.initials, bg: conv.bg, fg: conv.fg, online: conv.online)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: c.cobalt,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
    );
  }
}
