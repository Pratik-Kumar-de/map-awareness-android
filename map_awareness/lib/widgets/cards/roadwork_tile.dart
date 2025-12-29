import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/premium_expansion_tile.dart';


/// Widget displaying aggregated roadworks summary (Current, Soon, Future) in an expandable tile.
class RoadworksSummary extends StatelessWidget {
  final List<List<RoadworkDto>> roadworks;
  const RoadworksSummary({super.key, required this.roadworks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final total = roadworks[0].length + roadworks[1].length + roadworks[2].length;
    final items = [
      ...roadworks[0].map((r) => (r, cs.error, 'Ongoing')), 
      ...roadworks[1].map((r) => (r, cs.tertiary, 'Soon')), 
      ...roadworks[2].map((r) => (r, cs.primary, 'Future')),
    ];
    
    return PremiumExpansionTile(
      expansionKey: const PageStorageKey<String>('roadworks'),
      tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.construction_rounded, color: cs.onTertiaryContainer, size: 20),
      ),
      title: Text('$total Roadworks', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          _buildSummaryChip(cs.error, '${roadworks[0].length} Now'),
          _buildSummaryChip(cs.tertiary, '${roadworks[1].length} Soon'),
          _buildSummaryChip(cs.primary, '${roadworks[2].length} Later'),
        ]),
      ),
      children: items.map((i) => _RoadworkCard(data: i.$1, color: i.$2, status: i.$3)).toList(),
    );
  }

  Widget _buildSummaryChip(Color color, String label) {
    return Chip(
      avatar: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      label: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 8),
    );
  }
}

/// Individual card widget for a single roadwork event within the summary.
class _RoadworkCard extends StatelessWidget {
  final RoadworkDto data; final Color color; final String status;
  const _RoadworkCard({required this.data, required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = data.isBlocked ? theme.colorScheme.error : color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow, 
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('rw_${data.identifier.hashCode}'),
        tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(), collapsedShape: const Border(),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
          child: Icon(data.isBlocked ? Icons.block_rounded : Icons.construction_rounded, color: Colors.white, size: 20),
        ),
        title: Text(data.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            Chip(
              avatar: Icon(Icons.schedule_rounded, size: 16, color: c),
              label: Text(data.timeInfo, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: c.withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
            ),
            if (data.subtitle.isNotEmpty)
              Chip(
                avatar: Icon(Icons.navigation_rounded, size: 16, color: theme.colorScheme.primary),
                label: Text(data.subtitle, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                side: BorderSide.none,
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.only(right: 8),
              ),
          ]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
          child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        onExpansionChanged: (_) => Haptics.select(),
        children: [_Expanded(data: data, color: c)],
      ),
    );
  }
}

/// Component for the expanded detail view of a roadwork card.
class _Expanded extends StatelessWidget {
  final RoadworkDto data; final Color color;
  const _Expanded({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 24),
      if (data.isBlocked) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.block, size: 16, color: theme.colorScheme.error), 
            const SizedBox(width: 8), 
            Text('Road blocked', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      Row(children: [
        Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(data.formattedTimeRange, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 12),
      if (data.descriptionText.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer, 
            borderRadius: BorderRadius.circular(10), 
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(data.descriptionText, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
        ),
      ],
    ]);
  }
}

