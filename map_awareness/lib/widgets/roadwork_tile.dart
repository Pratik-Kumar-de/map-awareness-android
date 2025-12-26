import 'package:flutter/material.dart';
import 'package:map_awareness/models/routing_data.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Premium roadworks summary with gradient badges
class RoadworksSummary extends StatelessWidget {
  final List<List<RoutingWidgetData>> roadworks;

  const RoadworksSummary({super.key, required this.roadworks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = roadworks[0].length + roadworks[1].length + roadworks[2].length;
    
    final items = [
      ...roadworks[0].map((r) => (r, AppTheme.error, 'Ongoing')),
      ...roadworks[1].map((r) => (r, AppTheme.warning, 'Soon')),
      ...roadworks[2].map((r) => (r, AppTheme.info, 'Future')),
    ];
    
    return Semantics(
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const PageStorageKey<String>('roadworks_summary'),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.warning, AppTheme.warning.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.construction_rounded, color: Colors.white, size: 20),
          ),
          title: Text(
            '$total Roadworks',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                _buildCountBadge(roadworks[0].length, AppTheme.error, 'Now'),
                const SizedBox(width: 8),
                _buildCountBadge(roadworks[1].length, AppTheme.warning, 'Soon'),
                const SizedBox(width: 8),
                _buildCountBadge(roadworks[2].length, AppTheme.info, 'Later'),
              ],
            ),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          children: items.map((item) => RoadworkTile(
            data: item.$1,
            color: item.$2,
            statusLabel: item.$3,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium roadwork tile
class RoadworkTile extends StatelessWidget {
  final RoutingWidgetData data;
  final Color color;
  final String statusLabel;

  const RoadworkTile({
    super.key,
    required this.data,
    required this.color,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  data.typeLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (data.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
                if (data.infoSummary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.infoSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              data.time == 'ongoing' ? 'Now' : _formatTimestamp(data.time),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}.${dt.month}.';
    } catch (e) {
      return '';
    }
  }
}
