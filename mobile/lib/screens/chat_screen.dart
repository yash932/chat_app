import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/input_bar.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final chatProvider = Provider.of<ChatProvider>(context);
    final channel = chatProvider.currentChannel;
    final messages = chatProvider.messages;
    final currentUser = chatProvider.currentUser;
    final typingUsers = chatProvider.typingUsers;

    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        backgroundColor: c.paper,
        foregroundColor: c.ink,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.cobaltTint,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                channel != null
                    ? (channel.isDirect
                        ? (channel.displayName.substring(0, channel.displayName.length >= 2 ? 2 : 1).toUpperCase())
                        : (channel.icon.isEmpty ? '👥' : channel.icon))
                    : '💬',
                style: TextStyle(fontWeight: FontWeight.bold, color: c.cobalt, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel?.displayName ?? 'Chat',
                    style: AppTypography.subtitle(c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    channel != null && channel.description.isNotEmpty
                        ? channel.description
                        : (channel?.isDirect == true ? 'Direct conversation' : 'Group conversation'),
                    style: AppTypography.mono(c.inkTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoadingMessages
                ? Center(child: CircularProgressIndicator(color: c.cobalt, strokeWidth: 2))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              channel != null ? '✨ ${channel.displayName}' : 'No messages',
                              style: AppTypography.title(c.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send a message to start the conversation.',
                              style: AppTypography.caption(c.inkSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // Clean, smooth, non-jumping scroll with reverse: true
                        physics: const ClampingScrollPhysics(),
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          final isSelf = currentUser != null && msg.senderId == currentUser.id;

                          return ChatBubble(
                            key: ValueKey(msg.id),
                            message: msg,
                            isSelf: isSelf,
                            onReply: () => chatProvider.setReplyingTo(msg),
                            onReact: (emoji) => chatProvider.toggleReaction(msg.id, emoji),
                            onTogglePin: () => chatProvider.togglePin(msg.id),
                            onDelete: () => chatProvider.deleteMessage(msg.id),
                          );
                        },
                      ),
          ),

          // Typing indicator
          if (typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: c.cobalt),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${typingUsers.values.join(", ")} is typing…',
                    style: AppTypography.mono(c.inkTertiary),
                  ),
                ],
              ),
            ),

          // Input Dock
          InputBar(
            replyingTo: chatProvider.replyingToMessage,
            onCancelReply: () => chatProvider.setReplyingTo(null),
            onSend: (text, attachments) {
              chatProvider.sendMessage(text, attachments: attachments);
            },
            onTyping: (isTyping) {
              chatProvider.sendTyping(isTyping);
            },
          ),
        ],
      ),
    );
  }
}
