import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/avatar.dart';
import '../widgets/status_dot.dart';
import '../widgets/app_text_field.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showCreateGroupDialog(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final List<String> selectedMemberIds = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text('Create New Group', style: AppTypography.title(c.ink)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Group Name',
                      hint: 'e.g. Design Team',
                      controller: nameController,
                    ),
                    AppTextField(
                      label: 'Topic / Description',
                      hint: 'What is this group for?',
                      controller: descController,
                    ),
                    Text('Select Members', style: AppTypography.caption(c.inkSecondary).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: c.surfaceSunken,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.mist),
                      ),
                      child: provider.activeUsers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Center(
                                child: Text('No other members registered yet', style: AppTypography.caption(c.inkTertiary)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: provider.activeUsers.length,
                              itemBuilder: (context, idx) {
                                final u = provider.activeUsers[idx];
                                final isSelected = selectedMemberIds.contains(u.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  dense: true,
                                  title: Text(u.username, style: AppTypography.body(c.ink)),
                                  subtitle: Text(u.status, style: AppTypography.caption(c.inkTertiary)),
                                  activeColor: c.cobalt,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedMemberIds.add(u.id);
                                      } else {
                                        selectedMemberIds.remove(u.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: c.inkSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      await provider.createGroup(name, descController.text.trim(), selectedMemberIds);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      }
                    }
                  },
                  child: const Text('Create Group'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStartDMDialog(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final users = provider.activeUsers;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Direct Message', style: AppTypography.title(c.ink)),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('No other registered users yet', style: AppTypography.caption(c.inkSecondary)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, idx) {
                        final u = users[idx];
                        final initials = (u.username.isNotEmpty ? u.username : 'U').substring(0, 2).toUpperCase();
                        return ListTile(
                          leading: Avatar(
                            initials: initials,
                            status: u.status == 'online' ? PresenceStatus.online : PresenceStatus.offline,
                          ),
                          title: Text(u.username, style: AppTypography.bodyStrong(c.ink)),
                          subtitle: Text(u.customStatus.isNotEmpty ? u.customStatus : u.status, style: AppTypography.caption(c.inkSecondary)),
                          onTap: () {
                            Navigator.pop(ctx);
                            provider.startDirectMessage(u.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatScreen()),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final provider = Provider.of<ChatProvider>(context);
    final currentUser = provider.currentUser;
    final currentUserName = currentUser?.username ?? 'User';
    final userInitials = currentUserName.substring(0, currentUserName.length >= 2 ? 2 : 1).toUpperCase();

    final filteredDMs = provider.directMessages.where((dm) => dm.displayName.toLowerCase().contains(_searchQuery)).toList();
    final filteredGroups = provider.groups.where((grp) => grp.displayName.toLowerCase().contains(_searchQuery)).toList();

    final tabs = [
      // Tab 0: Chats (Groups + DMs)
      Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(
          child: Column(
            children: [
              // ==================== PROMINENT ACTIVE USER BANNER ====================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(bottom: BorderSide(color: c.mist)),
                ),
                child: Row(
                  children: [
                    Avatar(
                      initials: userInitials,
                      size: AvatarSize.md,
                      background: c.cobalt,
                      foreground: c.onCobalt,
                      status: PresenceStatus.online,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGGED IN AS',
                            style: AppTypography.mono(c.inkTertiary).copyWith(fontSize: 10.5, letterSpacing: 0.5),
                          ),
                          Text(
                            currentUserName,
                            style: AppTypography.bodyStrong(c.ink).copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '● Online',
                            style: TextStyle(fontSize: 12, color: c.signalGreen, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: c.coral, size: 20),
                      tooltip: 'Log out',
                      onPressed: () async {
                        await provider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Title Row & Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Text('Conversations', style: AppTypography.title(c.ink)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit_square, color: c.cobalt, size: 20),
                      tooltip: 'Direct Message',
                      onPressed: () => _showStartDMDialog(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.group_add, color: c.cobalt, size: 22),
                      tooltip: 'New Group',
                      onPressed: () => _showCreateGroupDialog(context),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: c.inkTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (q) => setState(() => _searchQuery = q.toLowerCase().trim()),
                          style: TextStyle(fontSize: 14, color: c.ink),
                          decoration: InputDecoration(
                            hintText: 'Search direct chats & groups',
                            hintStyle: TextStyle(fontSize: 14, color: c.inkTertiary),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Conversation list
              Expanded(
                child: provider.conversations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 40, color: c.inkTertiary),
                              const SizedBox(height: 12),
                              Text('No conversations yet', style: AppTypography.subtitle(c.ink)),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Group" or start a direct chat to begin messaging.',
                                style: AppTypography.caption(c.inkSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.group_add, size: 18),
                                label: const Text('Create New Group'),
                                onPressed: () => _showCreateGroupDialog(context),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          if (filteredGroups.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'GROUPS',
                                style: AppTypography.mono(c.inkTertiary).copyWith(fontSize: 11, letterSpacing: 0.6),
                              ),
                            ),
                            ...filteredGroups.map((grp) {
                              return ConversationTile(
                                name: grp.displayName,
                                preview: grp.lastMessageText ?? grp.description,
                                time: '',
                                initials: grp.icon.isNotEmpty ? grp.icon : '👥',
                                avatarBg: c.cobaltTint,
                                avatarFg: c.cobalt,
                                onTap: () {
                                  provider.selectChannel(grp);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                                  );
                                },
                              );
                            }),
                          ],
                          if (filteredDMs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 14.0, bottom: 8.0),
                              child: Text(
                                'DIRECT MESSAGES',
                                style: AppTypography.mono(c.inkTertiary).copyWith(fontSize: 11, letterSpacing: 0.6),
                              ),
                            ),
                            ...filteredDMs.map((dm) {
                              final initials = dm.displayName.substring(0, dm.displayName.length >= 2 ? 2 : 1).toUpperCase();
                              return ConversationTile(
                                name: dm.displayName,
                                preview: dm.lastMessageText ?? dm.otherCustomStatus ?? 'Direct conversation',
                                time: '',
                                initials: initials,
                                avatarBg: const Color(0xFFF1E4D8),
                                avatarFg: const Color(0xFF8A5A2B),
                                online: dm.otherStatus == 'online',
                                onTap: () {
                                  provider.selectChannel(dm);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                                  );
                                },
                              );
                            }),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),

      // Tab 1: Members Tab
      Scaffold(
        backgroundColor: c.paper,
        appBar: AppBar(
          title: Text('Members & Contacts (${provider.activeUsers.length})', style: AppTypography.title(c.ink)),
        ),
        body: provider.activeUsers.isEmpty
            ? Center(child: Text('No other members registered yet', style: AppTypography.caption(c.inkSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.activeUsers.length,
                itemBuilder: (context, idx) {
                  final user = provider.activeUsers[idx];
                  final initials = (user.username.isNotEmpty ? user.username : 'U').substring(0, 2).toUpperCase();

                  return ListTile(
                    leading: Avatar(
                      initials: initials,
                      status: user.status == 'online' ? PresenceStatus.online : PresenceStatus.offline,
                    ),
                    title: Text(user.username, style: AppTypography.bodyStrong(c.ink)),
                    subtitle: Text(user.customStatus.isNotEmpty ? user.customStatus : user.status, style: AppTypography.caption(c.inkSecondary)),
                    trailing: IconButton(
                      icon: Icon(Icons.chat_bubble_outline, color: c.cobalt, size: 20),
                      onPressed: () {
                        provider.startDirectMessage(user.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      },
                    ),
                  );
                },
              ),
      ),

      // Tab 2: Profile & Settings Tab
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
