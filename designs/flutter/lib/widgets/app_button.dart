import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppSemanticColors>()!;

    late final Color bg;
    late final Color fg;
    Border? border;
    final double height = variant == AppButtonVariant.ghost ? 36 : 48;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = c.cobalt;
        fg = c.onCobalt;
        break;
      case AppButtonVariant.secondary:
        bg = Colors.transparent;
        fg = c.ink;
        border = Border.all(color: c.mistStrong);
        break;
      case AppButtonVariant.danger:
        bg = Colors.transparent;
        fg = c.coral;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.inkSecondary;
        break;
    }

    final button = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border?.top ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.bodyStrong(fg)),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
