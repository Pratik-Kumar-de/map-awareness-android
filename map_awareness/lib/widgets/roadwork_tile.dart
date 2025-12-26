import 'package:flutter/material.dart';
import 'package:map_awareness/models/routing_data.dart';

/// Displays a collapsible summary of roadworks on a route.
class RoadworksSummary extends StatelessWidget {
  // [ongoing, shortTerm, future]
  final List<List<RoutingWidgetData>> roadworks;

  const RoadworksSummary({super.key, required this.roadworks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final total = roadworks[0].length + roadworks[1].length + roadworks[2].length;
    // [ongoing, shortTerm, future]
    // Use theme colors directly instead of raw material colors
    final items = [
      ...roadworks[0].map((r) => (r, colorScheme.error)),
      ...roadworks[1].map((r) => (r, colorScheme.tertiary)),
      ...roadworks[2].map((r) => (r, colorScheme.secondary)),
    ];
    
    // Semantics wrapper suppresses Windows accessibility bug (Flutter #179563)
    return Semantics(
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const PageStorageKey<String>('roadworks_summary'),
          initiallyExpanded: false,
          leading: Icon(Icons.construction, color: colorScheme.primary),
          title: Text('$total Roadworks on Route', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${roadworks[0].length} ongoing • ${roadworks[1].length} short-term • ${roadworks[2].length} future',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          backgroundColor: colorScheme.surfaceContainer,
          shape: const Border(),
          children: items.map((item) => RoadworkTile(data: item.$1, color: item.$2)).toList(),
        ),
      ),
    );
  }
}

/// Displays a single roadwork item.
class RoadworkTile extends StatelessWidget {
  final RoutingWidgetData data;
  final Color color;

  const RoadworkTile({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          data.typeLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(data.title, style: theme.textTheme.bodyMedium),
      subtitle: (data.subtitle.isEmpty && data.infoSummary.isEmpty) 
          ? null 
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.subtitle.isNotEmpty)
                  Text(data.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                if (data.infoSummary.isNotEmpty)
                  Text(
                    data.infoSummary, 
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
      trailing: Text(
        data.time == 'ongoing' ? 'Now' : _formatTimestamp(data.time),
        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
      ),
    );
  }

  /// Formats an ISO timestamp to a short date string.
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}.${dt.month}.';
    } catch (e) {
      return '';
    }
  }
}
