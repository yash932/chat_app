import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool fromMe;
  final bool read;

  const ChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.fromMe,
    this.read = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Signature detail: the corner on the message's own side is squared to
    // 4px instead of rounded — this replaces the usual speech-tail graphic.
    final radius = fromMe
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

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
        child: Column(
          crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: fromMe ? c.cobalt : c.surface,
                borderRadius: radius,
                border: fromMe ? null : Border.all(color: c.mist),
              ),
              child: Text(
                text,
                style: AppTypography.body(fromMe ? c.onCobalt : c.ink),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: AppTypography.mono(c.inkTertiary)),
                if (fromMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 13,
                    color: read ? c.cobalt : c.inkTertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
