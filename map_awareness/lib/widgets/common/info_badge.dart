import 'package:flutter/material.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Reusable info badge for displaying icon + label + optional value
class InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? color;

  const InfoBadge({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    
    if (value != null) {
      // Two-line badge with label and value
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                Text(value!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    }

    // Simple chip badge
    return Chip(
      avatar: Icon(icon, size: 14, color: c),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      backgroundColor: AppTheme.surfaceContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(0),
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}
