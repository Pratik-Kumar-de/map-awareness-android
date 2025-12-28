import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () {
          Haptics.select();
          onPressed?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: onPressed != null ? c.withValues(alpha: 0.5) : AppTheme.surfaceContainerHigh,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(c)))
              else if (icon != null)
                Icon(icon, color: c, size: 18),
              if (!isLoading && icon != null) const SizedBox(width: 8),
              if (!isLoading)
                Text(label, style: TextStyle(color: onPressed != null ? c : AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
