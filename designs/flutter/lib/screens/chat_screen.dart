import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/status_dot.dart';

class _Message {
  final String text, time;
  final bool fromMe, read;
  const _Message(this.text, this.time, this.fromMe, {this.read = false});
}

class ChatScreen extends StatefulWidget {
  final String name;
  final String initials;
  final Color bg;
  final Color fg;
  final bool online;

  const ChatScreen({
    super.key,
    this.name = 'Riya Mehta',
    this.initials = 'RM',
    this.bg = const Color(0xFFF1E4D8),
    this.fg = const Color(0xFF8A5A2B),
    this.online = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_Message> _messages = [
    const _Message('Hey! Are we still on for the design review today?', '09:32', false),
    const _Message("Yep, I've got the updated flows ready.", '09:35', true, read: true),
    const _Message("I'll share the file 10 minutes before so you have time to skim it.", '09:35', true, read: true),
    const _Message('Perfect. Should we do it in the usual room or on a call?', '09:38', false),
    const _Message('Sounds good, see you then!', '09:41', false),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _messages.add(_Message(text, time, true, read: false));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              initials: widget.initials,
              background: widget.bg,
              foreground: widget.fg,
              size: AvatarSize.sm,
              status: widget.online ? PresenceStatus.online : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.name, style: AppTypography.bodyStrong(c.ink)),
                Text(widget.online ? 'Online' : 'Offline', style: AppTypography.caption(c.inkSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = _messages[i];
                return ChatBubble(text: m.text, time: m.time, fromMe: m.fromMe, read: m.read);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.mist))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}, color: c.inkSecondary),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.mistStrong),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        style: AppTypography.body(c.ink),
                        decoration: const InputDecoration(
                          hintText: 'Write a message…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: c.cobalt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
