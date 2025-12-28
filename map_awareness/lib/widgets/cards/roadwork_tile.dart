import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';


class RoadworksSummary extends StatelessWidget {
  final List<List<RoadworkDto>> roadworks;
  const RoadworksSummary({super.key, required this.roadworks});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = roadworks[0].length + roadworks[1].length + roadworks[2].length;
    final items = [...roadworks[0].map((r) => (r, AppTheme.error, 'Ongoing')), ...roadworks[1].map((r) => (r, AppTheme.warning, 'Soon')), ...roadworks[2].map((r) => (r, AppTheme.info, 'Future'))];
    
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: AppTheme.cardShadow),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey<String>('roadworks'),
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.warning, AppTheme.warning.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.construction_rounded, color: Colors.white, size: 20),
        ),
        title: Text('$total Roadworks', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            Chip(
              avatar: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.error, shape: BoxShape.circle)),
              label: Text('${roadworks[0].length} Now', style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.error.withValues(alpha: 0.12),
              side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
            ),
            Chip(
              avatar: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
              label: Text('${roadworks[1].length} Soon', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
              side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.3)),
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
            ),
            Chip(
              avatar: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.info, shape: BoxShape.circle)),
              label: Text('${roadworks[2].length} Later', style: TextStyle(color: AppTheme.info, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.info.withValues(alpha: 0.12),
              side: BorderSide(color: AppTheme.info.withValues(alpha: 0.3)),
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
            ),
          ]),
        ),
        shape: const Border(), collapsedShape: const Border(),
        onExpansionChanged: (_) => HapticFeedback.selectionClick(),
        children: items.map((i) => _RoadworkCard(data: i.$1, color: i.$2, status: i.$3)).toList(),
      ),
    );
  }
}

class _RoadworkCard extends StatelessWidget {
  final RoadworkDto data; final Color color; final String status;
  const _RoadworkCard({required this.data, required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = data.isBlocked ? AppTheme.error : color;
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(AppTheme.radiusMd), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('rw_${data.identifier.hashCode}'),
        tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(), collapsedShape: const Border(),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(10)),
          child: Icon(data.isBlocked ? Icons.block_rounded : Icons.construction_rounded, color: Colors.white, size: 20),
        ),
        title: Text(data.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                avatar: Icon(Icons.navigation_rounded, size: 16, color: AppTheme.info),
                label: Text(data.subtitle, style: TextStyle(color: AppTheme.info, fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.info.withValues(alpha: 0.1),
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
          decoration: BoxDecoration(gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(16)),
          child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        onExpansionChanged: (_) => HapticFeedback.selectionClick(),
        children: [_Expanded(data: data, color: c)],
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  final RoadworkDto data; final Color color;
  const _Expanded({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 24),
      if (data.isBlocked) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [Icon(Icons.block, size: 16, color: AppTheme.error), const SizedBox(width: 8), Text('Road blocked', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 13))]),
        ),
        const SizedBox(height: 12),
      ],
      Row(children: [
        Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(data.formattedTimeRange, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 12),
      if (data.descriptionText.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: color, width: 3))),
          child: Text(data.descriptionText, style: t.textTheme.bodySmall?.copyWith(height: 1.5)),
        ),
      ],
    ]);
  }
}

