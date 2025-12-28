import 'package:flutter/material.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// Stats row showing multiple stat items
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

  Widget _buildStat(BuildContext context, StatItem item) {
    return Column(
      children: [
        Text(
          item.value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: item.color ?? AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final Color? color;
  const StatItem({required this.label, required this.value, this.color});
}
