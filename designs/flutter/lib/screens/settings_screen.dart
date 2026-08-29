import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _sound = true;
  bool _readReceipts = true;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppTypography.title(c.ink))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel('Notifications', c),
          _Card(c, children: [
            _ToggleRow(c, title: 'Push notifications', subtitle: 'Get notified about new messages', value: _push, onChanged: (v) => setState(() => _push = v)),
            _Divider(c),
            _ToggleRow(c, title: 'Message sound', value: _sound, onChanged: (v) => setState(() => _sound = v)),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('Privacy', c),
          _Card(c, children: [
            _ToggleRow(
              c,
              title: 'Read receipts',
              subtitle: "Let others see when you've read their message",
              value: _readReceipts,
              onChanged: (v) => setState(() => _readReceipts = v),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('Appearance', c),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, mode, _) => _Card(c, children: [
              _ToggleRow(
                c,
                title: 'Dark mode',
                value: mode == ThemeMode.dark,
                onChanged: (v) => ThemeController.mode.value = v ? ThemeMode.dark : ThemeMode.light,
              ),
            ]),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Session', c),
          AppButton(
            label: 'Log out',
            variant: AppButtonVariant.danger,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
          ),
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

class _ToggleRow extends StatelessWidget {
  final AppSemanticColors c;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(this.c, {required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyStrong(c.ink).copyWith(fontSize: 14.5)),
                  if (subtitle != null) Text(subtitle!, style: AppTypography.caption(c.inkSecondary)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}
