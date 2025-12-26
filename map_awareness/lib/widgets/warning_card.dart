import 'package:flutter/material.dart';
import 'package:map_awareness/models/warning_item.dart';

// --- Color constants for severity levels ---
const _kExtremeColor = Color(0xFFD32F2F);
const _kExtremeColorDark = Color(0xFFB71C1C);
const _kSevereColor = Color(0xFFE65100);
const _kSevereColorDark = Color(0xFFBF360C);
const _kModerateColor = Color(0xFFF9A825);
const _kModerateColorDark = Color(0xFFF57F17);
const _kMinorColor = Color(0xFF1976D2);
const _kMinorColorDark = Color(0xFF0D47A1);

/// Modern warning card with gradient, expandable details
class WarningCard extends StatelessWidget {
  final WarningItem warning;
  final VoidCallback? onTap;

  const WarningCard({super.key, required this.warning, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getSeverityColors(warning.severity);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.08),
              colors.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>('warning_${warning.title.hashCode}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: _SeverityIcon(colors: colors, category: warning.category),
          title: Text(
            warning.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _WarningChips(warning: warning, colors: colors),
          trailing: _SeverityBadge(severity: warning.severity, colors: colors),
          children: [_ExpandedContent(warning: warning, colors: colors)],
        ),
      ),
    );
  }

  _SeverityColors _getSeverityColors(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.extreme:
        return _SeverityColors(_kExtremeColor, _kExtremeColorDark);
      case WarningSeverity.severe:
        return _SeverityColors(_kSevereColor, _kSevereColorDark);
      case WarningSeverity.moderate:
        return _SeverityColors(_kModerateColor, _kModerateColorDark);
      case WarningSeverity.minor:
        return _SeverityColors(_kMinorColor, _kMinorColorDark);
    }
  }
}

class _SeverityColors {
  final Color primary;
  final Color secondary;
  const _SeverityColors(this.primary, this.secondary);
}

class _SeverityIcon extends StatelessWidget {
  final _SeverityColors colors;
  final WarningCategory category;

  const _SeverityIcon({required this.colors, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(_getCategoryIcon(category), color: Colors.white, size: 24),
    );
  }

  IconData _getCategoryIcon(WarningCategory category) {
    switch (category) {
      case WarningCategory.weather:
        return Icons.thunderstorm;
      case WarningCategory.flood:
        return Icons.water;
      case WarningCategory.fire:
        return Icons.local_fire_department;
      case WarningCategory.health:
        return Icons.health_and_safety;
      case WarningCategory.civil:
        return Icons.campaign;
      case WarningCategory.environment:
        return Icons.eco;
      case WarningCategory.other:
        return Icons.warning_amber;
    }
  }
}

class _WarningChips extends StatelessWidget {
  final WarningItem warning;
  final _SeverityColors colors;

  const _WarningChips({required this.warning, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildChip(warning.relativeTimeInfo, Icons.schedule, colors.primary, theme),
          _buildChip(
            warning.source,
            warning.source == 'DWD' ? Icons.cloud : Icons.shield,
            warning.source == 'DWD' ? Colors.blue : Colors.deepPurple,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final WarningSeverity severity;
  final _SeverityColors colors;

  const _SeverityBadge({required this.severity, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final WarningItem warning;
  final _SeverityColors colors;

  const _ExpandedContent({required this.warning, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeInfo(theme),
        const SizedBox(height: 12),
        _buildStatusIndicator(theme),
        const SizedBox(height: 12),
        _buildDescription(theme),
        if (warning.severity.level >= 3) ...[
          const SizedBox(height: 12),
          _buildSeverityHint(theme),
        ],
      ],
    );
  }

  Widget _buildTimeInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.access_time_filled,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Duration: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            warning.formattedTimeRange,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final Color statusColor;
    final String statusText;

    if (warning.hasEnded) {
      statusColor = Colors.grey;
      statusText = 'Ended';
    } else if (warning.isActive) {
      statusColor = Colors.green;
      statusText = 'Currently Active';
    } else {
      statusColor = Colors.orange;
      statusText = 'Upcoming';
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Text(
        warning.description.isNotEmpty
            ? warning.description
            : 'No additional details available.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildSeverityHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning.severity.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary header showing warning statistics
class WarningsSummary extends StatelessWidget {
  final List<WarningItem> warnings;

  const WarningsSummary({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final counts = _WarningCounts(
      extreme: warnings.where((w) => w.severity == WarningSeverity.extreme).length,
      severe: warnings.where((w) => w.severity == WarningSeverity.severe).length,
      moderate: warnings.where((w) => w.severity == WarningSeverity.moderate).length,
      minor: warnings.where((w) => w.severity == WarningSeverity.minor).length,
      active: warnings.where((w) => w.isActive).length,
      total: warnings.length,
    );

    if (warnings.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildSummaryCard(theme, counts);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Warnings',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Your area is currently safe',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, _WarningCounts counts) {
    final status = _getOverallStatus(counts);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status.color.withValues(alpha: 0.12),
            status.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildStatusHeader(theme, status, counts),
          const SizedBox(height: 16),
          _buildSeverityBreakdown(theme, counts),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme, _OverallStatus status, _WarningCounts counts) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(status.icon, color: status.color, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.text,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${counts.active} of ${counts.total} active',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBreakdown(ThemeData theme, _WarningCounts counts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CountBadge(label: 'Extreme', count: counts.extreme, color: _kExtremeColor),
        _CountBadge(label: 'Severe', count: counts.severe, color: _kSevereColor),
        _CountBadge(label: 'Moderate', count: counts.moderate, color: _kModerateColor),
        _CountBadge(label: 'Minor', count: counts.minor, color: _kMinorColor),
      ],
    );
  }

  _OverallStatus _getOverallStatus(_WarningCounts counts) {
    if (counts.extreme > 0) {
      return _OverallStatus(_kExtremeColor, 'Extreme Danger', Icons.dangerous);
    }
    if (counts.severe > 0) {
      return _OverallStatus(_kSevereColor, 'Severe Warnings', Icons.warning);
    }
    if (counts.moderate > 0) {
      return _OverallStatus(_kModerateColor, 'Moderate Warnings', Icons.warning_amber);
    }
    if (counts.minor > 0) {
      return _OverallStatus(_kMinorColor, 'Minor Alerts', Icons.info);
    }
    return _OverallStatus(Colors.green, 'All Clear', Icons.check_circle);
  }
}

class _WarningCounts {
  final int extreme;
  final int severe;
  final int moderate;
  final int minor;
  final int active;
  final int total;

  const _WarningCounts({
    required this.extreme,
    required this.severe,
    required this.moderate,
    required this.minor,
    required this.active,
    required this.total,
  });
}

class _OverallStatus {
  final Color color;
  final String text;
  final IconData icon;

  const _OverallStatus(this.color, this.text, this.icon);
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = count > 0;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? color : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? color : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Filter chips for warning severities
class WarningFilters extends StatelessWidget {
  final Set<WarningCategory> selectedCategories;
  final Set<WarningSeverity> selectedSeverities;
  final bool showOnlyActive;
  final ValueChanged<WarningCategory> onCategoryToggle;
  final ValueChanged<WarningSeverity> onSeverityToggle;
  final ValueChanged<bool> onActiveToggle;

  const WarningFilters({
    super.key,
    required this.selectedCategories,
    required this.selectedSeverities,
    required this.showOnlyActive,
    required this.onCategoryToggle,
    required this.onSeverityToggle,
    required this.onActiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            selected: showOnlyActive,
            label: const Text('Active Only'),
            avatar: Icon(
              Icons.access_time,
              size: 16,
              color: showOnlyActive ? null : null, 
            ),
            onSelected: (_) => onActiveToggle(!showOnlyActive),
          ),
          const SizedBox(width: 8),
          ...WarningSeverity.values.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selectedSeverities.contains(s),
              label: Text(s.label),
              onSelected: (_) => onSeverityToggle(s),
            ),
          )),
        ],
      ),
    );
  }
}
