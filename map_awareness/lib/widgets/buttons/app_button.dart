import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/utils/app_theme.dart';

enum AppButtonVariant { primary, secondary }

/// Unified button component supporting primary (gradient) and secondary (outline) styles.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final AppButtonVariant variant;
  final Gradient? gradient;
  final Color? color;

  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.gradient,
  }) : variant = AppButtonVariant.primary, color = null;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expanded = false,
    this.color,
  }) : variant = AppButtonVariant.secondary, gradient = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isPrimary = variant == AppButtonVariant.primary;
    
    // Effective color for secondary variant.
    final secColor = color ?? primary;
    
    // Background separation.
    final bgColor = isPrimary 
        ? (onPressed != null ? (gradient == null ? primary : null) : theme.colorScheme.surfaceContainerHigh)
        : Colors.transparent;
        
    final bgGradient = isPrimary && onPressed != null ? gradient : null;
    
    final border = !isPrimary 
        ? Border.all(
            color: onPressed != null ? secColor.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHigh,
            width: 1.5,
          )
        : null;

    final shadow = isPrimary && onPressed != null
        ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
        : null;

    // Text color.
    final textColor = isPrimary 
        ? (onPressed != null ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant)
        : (onPressed != null ? secColor : theme.colorScheme.onSurfaceVariant);

    return AnimatedContainer(
      duration: AppTheme.animNormal,
      width: expanded ? double.infinity : null,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: shadow,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            variant == AppButtonVariant.primary ? Haptics.medium() : Haptics.select();
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
                   SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, 
                      valueColor: AlwaysStoppedAnimation(isPrimary ? theme.colorScheme.onPrimary : secColor),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: textColor, size: 20),
                if (!isLoading && icon != null) const SizedBox(width: 10),
                if (!isLoading)
                  Text(
                    label, 
                    style: TextStyle(
                      color: textColor, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
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
