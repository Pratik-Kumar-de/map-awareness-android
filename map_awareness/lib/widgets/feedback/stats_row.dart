import 'package:flutter/material.dart';

import 'package:map_awareness/widgets/common/premium_card.dart';

/// Widget for displaying a row of statistic items (value + label).
class StatsRow extends StatelessWidget {
  final List<StatItem> items;
  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: items.map((item) => Expanded(child: _buildStat(context, item))).toList(),
      ),
    );
  }

  /// Builds an individual statistic item with value and label.
  Widget _buildStat(BuildContext context, StatItem item) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          item.value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: item.color ?? theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Data model for an individual statistic entry.
class StatItem {
  final String label;
  final String value;
  final Color? color;
  const StatItem({required this.label, required this.value, this.color});
}
