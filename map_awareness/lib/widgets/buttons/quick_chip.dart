import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Quick chip button.
class QuickChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Color? color;

  const QuickChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurfaceVariant;
    final borderCol = theme.colorScheme.surfaceContainerHigh;

    return Material(
      color: isSelected ? c.withValues(alpha: 0.12) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () {
          Haptics.select();
          onTap?.call();
        },
        onLongPress: () {
          Haptics.heavy();
          onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? c : borderCol, width: 1.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? c : textCol),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(color: isSelected ? c : textCol, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
