import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PresenceStatus { online, away, offline }

class StatusDot extends StatelessWidget {
  final PresenceStatus status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 11});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    late final Color color;
    switch (status) {
      case PresenceStatus.online:
        color = c.signalGreen;
        break;
      case PresenceStatus.away:
        color = c.amber;
        break;
      case PresenceStatus.offline:
        color = c.inkTertiary;
        break;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: c.surface, width: 2),
      ),
    );
  }
}
