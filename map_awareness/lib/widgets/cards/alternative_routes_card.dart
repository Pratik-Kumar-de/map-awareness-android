import 'package:flutter/material.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/premium_expansion_tile.dart';

/// Widget utilizing an ExpansionTile to display a list of all route options, allowing selection.
class AlternativeRoutesCard extends StatelessWidget {
  final List<RouteAlternative> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AlternativeRoutesCard({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onSelect,
  });

  /// Renders nothing if empty; otherwise builds the expandable list of routes with duration and distance.
  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty || routes.length < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return PremiumExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.alt_route_rounded, color: primary, size: 20),
      ),
      title: Text(
        '${routes.length} Route Options',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      children: routes.asMap().entries.map((entry) {
        final index = entry.key;
        final alt = entry.value;
        final isSelected = index == selectedIndex;
        
        final bgColor = isSelected ? primary : primary.withValues(alpha: 0.05);
        final textColor = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
        final mutedColor = isSelected ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: isSelected ? primary : primary.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            onTap: () {
              Haptics.select();
              onSelect(index);
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.onPrimary : primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? primary : Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 16, color: mutedColor),
                        const SizedBox(width: 4),
                        Text(
                          alt.durationFormatted, 
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.straighten_rounded, size: 16, color: mutedColor),
                        const SizedBox(width: 4),
                        Text(
                          alt.distanceFormatted, 
                          style: TextStyle(color: mutedColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: theme.colorScheme.onPrimary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
