import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/models/warning_item.dart';
import 'package:map_awareness/utils/app_theme.dart';

// Severity gradient colors
const _kExtremeColors = [Color(0xFFE53935), Color(0xFFC62828)];
const _kSevereColors = [Color(0xFFFF6D00), Color(0xFFE65100)];
const _kModerateColors = [Color(0xFFFFA000), Color(0xFFF57C00)];
const _kMinorColors = [Color(0xFF42A5F5), Color(0xFF1E88E5)];

/// Premium warning card with gradient accents
class WarningCard extends StatelessWidget {
  final WarningItem warning;
  final VoidCallback? onTap;

  const WarningCard({super.key, required this.warning, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getSeverityColors(warning.severity);

    return Container(
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
        title: Text(
          warning.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _WarningChips(warning: warning, colors: colors),
        ),
        trailing: _SeverityBadge(severity: warning.severity, colors: colors),
        onExpansionChanged: (_) => HapticFeedback.selectionClick(),
        children: [_ExpandedContent(warning: warning, colors: colors)],
      ),
    );
  }

  List<Color> _getSeverityColors(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.extreme:
        return _kExtremeColors;
      case WarningSeverity.severe:
        return _kSevereColors;
      case WarningSeverity.moderate:
        return _kModerateColors;
      case WarningSeverity.minor:
        return _kMinorColors;
    }
  }
}

class _SeverityIcon extends StatelessWidget {
  final List<Color> colors;
  final WarningCategory category;

  const _SeverityIcon({required this.colors, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(_getCategoryIcon(category), color: Colors.white, size: 22),
    );
  }

  IconData _getCategoryIcon(WarningCategory category) {
    switch (category) {
      case WarningCategory.weather:
        return Icons.thunderstorm_rounded;
      case WarningCategory.flood:
        return Icons.water_rounded;
      case WarningCategory.fire:
        return Icons.local_fire_department_rounded;
      case WarningCategory.health:
        return Icons.health_and_safety_rounded;
      case WarningCategory.civil:
        return Icons.campaign_rounded;
      case WarningCategory.environment:
        return Icons.eco_rounded;
      case WarningCategory.other:
        return Icons.warning_amber_rounded;
    }
  }
}

class _WarningChips extends StatelessWidget {
  final WarningItem warning;
  final List<Color> colors;

  const _WarningChips({required this.warning, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildChip(warning.relativeTimeInfo, Icons.schedule_rounded, colors.first),
        _buildChip(
          warning.source,
          warning.source == 'DWD' ? Icons.cloud_rounded : Icons.shield_rounded,
          warning.source == 'DWD' ? AppTheme.info : const Color(0xFF7C4DFF),
        ),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
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

class _SeverityBadge extends StatelessWidget {
  final WarningSeverity severity;
  final List<Color> colors;

  const _SeverityBadge({required this.severity, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        severity.label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

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
        
        // Time info
        _InfoRow(
          icon: Icons.access_time_filled_rounded,
          label: 'Duration',
          value: warning.formattedTimeRange,
        ),
        const SizedBox(height: 12),
        
        // Status
        _buildStatusIndicator(theme),
        const SizedBox(height: 16),
        
        // Description
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: colors.first, width: 4)),
          ),
          child: Text(
            warning.description.isNotEmpty
                ? warning.description
                : 'No additional details available.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
        
        // Severity hint for high severity
        if (warning.severity.level >= 3) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.first.withValues(alpha: 0.1),
                  colors.first.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.first.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_rounded, color: colors.first, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    warning.severity.hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.first,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

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
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Warning filters with premium chips
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
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'Active Only',
            icon: Icons.access_time_rounded,
            isSelected: showOnlyActive,
            onTap: () => onActiveToggle(!showOnlyActive),
          ),
          const SizedBox(width: 8),
          ...WarningSeverity.values.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: s.label,
              isSelected: selectedSeverities.contains(s),
              onTap: () => onSeverityToggle(s),
            ),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
