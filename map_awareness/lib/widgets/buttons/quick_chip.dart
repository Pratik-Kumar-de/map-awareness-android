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
    final c = color ?? AppTheme.primary;

    return Material(
      color: isSelected ? c.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        onTap: () {
          Haptics.select();
          onTap?.call();
        },
        onLongPress: () {
          Haptics.heavy();
          onLongPress?.call();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? c : AppTheme.surfaceContainerHigh, width: 1.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: isSelected ? c : AppTheme.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(color: isSelected ? c : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
