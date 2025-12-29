import 'package:flutter/material.dart';


/// Info badge widget.
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
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    
    if (value != null) {
      // Two-line badge.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh),
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
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.outline, fontWeight: FontWeight.w500)),
                Text(value!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );
    }

    // Simple chip badge.
    return Chip(
      avatar: Icon(icon, size: 14, color: c),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(0),
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}
