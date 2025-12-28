import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Primary gradient action button
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.durationFast,
      width: expanded ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: onPressed != null ? (gradient ?? AppTheme.primaryGradient) : null,
        color: onPressed == null ? AppTheme.surfaceContainerHigh : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: onPressed != null
            ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            HapticFeedback.mediumImpact();
            onPressed?.call();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20),
                if (!isLoading && icon != null) const SizedBox(width: 10),
                if (!isLoading)
                  Text(label, style: TextStyle(color: onPressed != null ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
