import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'attachment_view.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isSelf;
  final VoidCallback? onReply;
  final Function(String emoji)? onReact;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSelf,
    this.onReply,
    this.onReact,
    this.onTogglePin,
    this.onDelete,
  });

  void _showActionSheet(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '🔥', '👍', '😂', '🎉', '🚀'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onReact?.call(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surfaceSunken,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.reply, color: c.cobalt),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReply?.call();
                  },
                ),
                ListTile(
                  leading: Icon(message.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: c.amber),
                  title: Text(message.isPinned ? 'Unpin message' : 'Pin message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onTogglePin?.call();
                  },
                ),
                if (isSelf)
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: c.coral),
                    title: Text('Delete message', style: TextStyle(color: c.coral)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDelete?.call();
                    },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    // Signature detail: 16px radius with corner on sender's own side squared to 4px
    final radius = isSelf
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          );

    // Group reactions
    final Map<String, int> rxCounts = {};
    for (final r in message.reactions) {
      rxCounts[r.emoji] = (rxCounts[r.emoji] ?? 0) + 1;
    }

    return GestureDetector(
      onLongPress: () => _showActionSheet(context),
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.76),
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isSelf)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3.0, left: 4.0),
                    child: Text(
                      '@${message.senderName}',
                      style: AppTypography.caption(c.cobalt).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),

                // Main Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelf ? c.cobalt : c.surface,
                    borderRadius: radius,
                    border: isSelf ? null : Border.all(color: c.mist),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply Preview
                      if (message.replyToSender != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelf ? Colors.white.withValues(alpha: 0.15) : c.surfaceSunken,
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(color: isSelf ? Colors.white : c.cobalt, width: 2),
                            ),
                          ),
                          child: Text(
                            '↳ @${message.replyToSender}: ${message.replyToText ?? "[Attachment]"}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isSelf ? Colors.white70 : c.inkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Text
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: AppTypography.body(isSelf ? c.onCobalt : c.ink),
                        ),

                      // Attachments
                      if (message.attachments.isNotEmpty)
                        AttachmentView(attachments: message.attachments),
                    ],
                  ),
                ),

                // Meta row (time + ticks + pin)
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: AppTypography.mono(c.inkTertiary)),
                    if (message.isPinned) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.push_pin, size: 11, color: c.amber),
                    ],
                    if (isSelf) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all, size: 13, color: c.cobalt),
                    ],
                  ],
                ),

                // Emoji Reaction Badges
                if (rxCounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      spacing: 4,
                      children: rxCounts.entries.map((e) {
                        return GestureDetector(
                          onTap: () => onReact?.call(e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.mist),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${e.key} ${e.value}',
                              style: TextStyle(fontSize: 11.5, color: c.ink),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
