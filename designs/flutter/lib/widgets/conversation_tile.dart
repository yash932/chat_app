import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'avatar.dart';
import 'status_dot.dart';

class ConversationTile extends StatelessWidget {
  final String name;
  final String preview;
  final String time;
  final String initials;
  final Color avatarBg;
  final Color avatarFg;
  final int unreadCount;
  final bool online;
  final bool selected;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.name,
    required this.preview,
    required this.time,
    required this.initials,
    required this.avatarBg,
    required this.avatarFg,
    required this.onTap,
    this.unreadCount = 0,
    this.online = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;

    return Material(
      color: selected ? c.cobaltTint : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: selected ? c.cobalt : Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              Avatar(
                initials: initials,
                background: avatarBg,
                foreground: avatarFg,
                status: online ? PresenceStatus.online : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyStrong(c.ink),
                          ),
                        ),
                        Text(time, style: AppTypography.mono(c.inkTertiary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(c.inkSecondary),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(color: c.cobalt, borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              '$unreadCount',
                              textAlign: TextAlign.center,
                              style: AppTypography.mono(c.onCobalt).copyWith(fontSize: 10.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
