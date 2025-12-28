import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/models/warning_item.dart';

import 'package:map_awareness/utils/app_theme.dart';

/// Widget for displaying a warning item with expandable details.
class WarningCard extends StatelessWidget {
  final WarningItem warning;
  final VoidCallback? onTap;

  const WarningCard({super.key, required this.warning, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = warning.severity.gradient;

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
        key: PageStorageKey<String>('warning_${warning.title.hashCode}'),
        tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: _SeverityIcon(colors: colors, category: warning.category),
        title: Text(warning.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            Chip(
              avatar: Icon(Icons.schedule_rounded, size: 16, color: warning.severity.color),
              label: Text(warning.relativeTimeInfo, style: TextStyle(color: warning.severity.color, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: warning.severity.color.withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.only(right: 8),
            ),
            Chip(
              avatar: Icon(warning.source == 'DWD' ? Icons.cloud_rounded : Icons.shield_rounded, size: 16, color: warning.source == 'DWD' ? AppTheme.info : AppTheme.civil),
              label: Text(warning.source, style: TextStyle(color: warning.source == 'DWD' ? AppTheme.info : AppTheme.civil, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: (warning.source == 'DWD' ? AppTheme.info : AppTheme.civil).withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
              labelPadding: const EdgeInsets.only(right: 8),
            ),
          ]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(warning.severity.label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        onExpansionChanged: (_) => Haptics.select(),
        children: [_ExpandedContent(warning: warning, colors: colors)],
      ),
    ),
  );
  }
}

/// Icon component indicating the severity and category of a warning.
class _SeverityIcon extends StatelessWidget {
  final List<Color> colors;
  final WarningCategory category;
  const _SeverityIcon({required this.colors, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(_getCategoryIcon(category), color: Colors.white, size: 22),
    );
  }

  /// Maps warning category to specific icon data.
  IconData _getCategoryIcon(WarningCategory category) => switch (category) {
    WarningCategory.weather => Icons.thunderstorm_rounded,
    WarningCategory.flood => Icons.water_rounded,
    WarningCategory.fire => Icons.local_fire_department_rounded,
    WarningCategory.health => Icons.health_and_safety_rounded,
    WarningCategory.civil => Icons.campaign_rounded,
    WarningCategory.environment => Icons.eco_rounded,
    WarningCategory.other => Icons.warning_amber_rounded,
  };
}

/// Component for the expanded detail view of a warning card.
class _ExpandedContent extends StatelessWidget {
  final WarningItem warning;
  final List<Color> colors;
  const _ExpandedContent({required this.warning, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),

        Row(children: [
          Icon(Icons.access_time_filled_rounded, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text('Duration: ', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          Expanded(child: Text(warning.formattedTimeRange, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),

        _buildStatusIndicator(theme),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: colors.first, width: 4))),
          child: Text(warning.description.isNotEmpty ? warning.description : 'No additional details available.', style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
        ),

        if (warning.severity.level >= 3) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors.first.withValues(alpha: 0.1), colors.first.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.first.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: colors.first.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.info_rounded, color: colors.first, size: 16)),
              const SizedBox(width: 10),
              Expanded(child: Text(warning.severity.hint, style: theme.textTheme.bodySmall?.copyWith(color: colors.first, fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
      ],
    );
  }

  /// Builds a visual indicator for the warning's temporal status (active, ended, upcoming).
  Widget _buildStatusIndicator(ThemeData theme) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (warning.hasEnded) {
      statusColor = AppTheme.textMuted;
      statusText = 'Ended';
      statusIcon = Icons.check_circle_rounded;
    } else if (warning.isActive) {
      statusColor = AppTheme.success;
      statusText = 'Currently Active';
      statusIcon = Icons.radio_button_on_rounded;
    } else {
      statusColor = AppTheme.warning;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(statusIcon, size: 14, color: statusColor),
        const SizedBox(width: 6),
        Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
