import 'package:flutter/material.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// Widget utilizing an ExpansionTile to display a list of alternative route options.
class AlternativeRoutesCard extends StatelessWidget {
  final List<RouteAlternative> alternatives;

  const AlternativeRoutesCard({
    super.key,
    required this.alternatives,
  });

  /// Renders nothing if empty; otherwise builds the expandable list of routes with duration and distance.
  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.alt_route_rounded, color: AppTheme.primary, size: 20),
        ),
        title: Text(
          '${alternatives.length} Alternative Route${alternatives.length > 1 ? 's' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: alternatives.asMap().entries.map((entry) {
          final index = entry.key;
          final alt = entry.value;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 2}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(alt.durationFormatted, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(width: 12),
                          Icon(Icons.straighten_rounded, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(alt.distanceFormatted, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
