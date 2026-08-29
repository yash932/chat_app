import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/status_dot.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusMsgController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  String _selectedStatus = 'online';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final user = provider.currentUser;
    if (user != null) {
      _nameController.text = user.username;
      _statusMsgController.text = user.customStatus;
      _selectedStatus = user.status;
    }
    _serverUrlController.text = ApiService.baseUrl;
  }

  Future<void> _saveProfile() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final randSeed = 'seed_${Random().nextInt(999999)}';
    final avatar = 'https://api.dicebear.com/7.x/identicon/svg?seed=$randSeed';

    await provider.updateProfile(
      username: name,
      status: _selectedStatus,
      customStatus: _statusMsgController.text.trim(),
      avatar: avatar,
    );

    if (_serverUrlController.text.trim().isNotEmpty &&
        _serverUrlController.text.trim() != ApiService.baseUrl) {
      await provider.updateServerUrl(_serverUrlController.text.trim());
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final provider = Provider.of<ChatProvider>(context);
    final initials = (_nameController.text.isNotEmpty ? _nameController.text : 'JL').substring(0, 2).toUpperCase();

    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppTypography.title(c.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Avatar(
                  initials: initials,
                  size: AvatarSize.lg,
                  status: _selectedStatus == 'online' ? PresenceStatus.online : PresenceStatus.offline,
                ),
                const SizedBox(height: 12),
                Text(_nameController.text, style: AppTypography.title(c.ink)),
                const SizedBox(height: 2),
                Text(
                  '@${_nameController.text.toLowerCase().replaceFirst(' ', '')} · ${_statusMsgController.text.isNotEmpty ? _statusMsgController.text : "Active"}',
                  style: AppTypography.caption(c.inkSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section 1: Account
          Text('ACCOUNT', style: AppTypography.mono(c.inkTertiary).copyWith(fontSize: 11, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.mist),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: c.inkSecondary, size: 20),
                  title: Text('Display Name', style: AppTypography.caption(c.inkSecondary)),
                  subtitle: TextField(
                    controller: _nameController,
                    style: AppTypography.body(c.ink),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 2)),
                  ),
                ),
                Divider(color: c.mist, height: 1),
                ListTile(
                  leading: Icon(Icons.emoji_emotions_outlined, color: c.inkSecondary, size: 20),
                  title: Text('Custom Status', style: AppTypography.caption(c.inkSecondary)),
                  subtitle: TextField(
                    controller: _statusMsgController,
                    style: AppTypography.body(c.ink),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Preferences
          Text('PREFERENCES', style: AppTypography.mono(c.inkTertiary).copyWith(fontSize: 11, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.mist),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: c.inkSecondary, size: 20),
                  title: Text('Dark Mode', style: AppTypography.body(c.ink)),
                  trailing: Switch(
                    value: provider.themeMode == 'dark',
                    onChanged: (val) => provider.toggleTheme(val ? 'dark' : 'light'),
                  ),
                ),
                Divider(color: c.mist, height: 1),
                ListTile(
                  leading: Icon(Icons.dns_outlined, color: c.inkSecondary, size: 20),
                  title: Text('Server URL', style: AppTypography.caption(c.inkSecondary)),
                  subtitle: TextField(
                    controller: _serverUrlController,
                    style: AppTypography.mono(c.ink),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 2)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Save Button
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
