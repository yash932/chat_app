import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar.dart';
import '../widgets/status_dot.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: AppTypography.title(c.ink))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const Avatar(initials: 'JL', size: AvatarSize.lg, status: PresenceStatus.online),
                const SizedBox(height: 14),
                Text('Jordan Lee', style: AppTypography.title(c.ink)),
                const SizedBox(height: 2),
                Text('@jordanlee · Product designer', style: AppTypography.caption(c.inkSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SectionLabel('Account', c),
          _Card(c, children: [
            _Row(c, icon: Icons.mail_outline, title: 'Email', subtitle: 'jordan.lee@example.com'),
            _Divider(c),
            _Row(c, icon: Icons.call_outlined, title: 'Phone', subtitle: '+91 98765 43210'),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('More', c),
          _Card(c, children: [
            _Row(
              c,
              icon: Icons.settings_outlined,
              title: 'Settings',
              trailing: Icons.chevron_right,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppSemanticColors c;
  const _SectionLabel(this.text, this.c);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: AppTypography.caption(c.inkTertiary).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        ),
      );
}

class _Card extends StatelessWidget {
  final AppSemanticColors c;
  final List<Widget> children;
  const _Card(this.c, {required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.mist),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  final AppSemanticColors c;
  const _Divider(this.c);
  @override
  Widget build(BuildContext context) => Divider(height: 1, color: c.mist);
}

class _Row extends StatelessWidget {
  final AppSemanticColors c;
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;
  const _Row(this.c, {required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: c.inkSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyStrong(c.ink).copyWith(fontSize: 14.5)),
                    if (subtitle != null) Text(subtitle!, style: AppTypography.caption(c.inkSecondary)),
                  ],
                ),
              ),
              if (trailing != null) Icon(trailing, size: 18, color: c.inkTertiary),
            ],
          ),
        ),
      );
}
