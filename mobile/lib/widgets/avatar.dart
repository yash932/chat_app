import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'status_dot.dart';

enum AvatarSize { sm, md, lg }

class Avatar extends StatelessWidget {
  final String initials;
  final Color? background;
  final Color? foreground;
  final ImageProvider? image;
  final AvatarSize size;
  final PresenceStatus? status;

  const Avatar({
    super.key,
    required this.initials,
    this.background,
    this.foreground,
    this.image,
    this.size = AvatarSize.md,
    this.status,
  });

  double get _dimension {
    switch (size) {
      case AvatarSize.sm:
        return 36;
      case AvatarSize.md:
        return 44;
      case AvatarSize.lg:
        return 84;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.sm:
        return 13;
      case AvatarSize.md:
        return 15;
      case AvatarSize.lg:
        return 28;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;
    final bg = background ?? c.cobaltTint;
    final fg = foreground ?? c.cobalt;

    final circle = Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        image: image != null ? DecorationImage(image: image!, fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(
              initials,
              style: AppTypography.bodyStrong(fg).copyWith(fontSize: _fontSize),
            )
          : null,
    );

    if (status == null) return circle;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          right: -1,
          bottom: -1,
          child: StatusDot(status: status!, size: _dimension * 0.26),
        ),
      ],
    );
  }
}
