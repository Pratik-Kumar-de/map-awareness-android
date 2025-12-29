import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_awareness/providers/app_providers.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/utils/helpers.dart';

/// Bottom sheet for comparing and selecting route alternatives.
class RouteComparisonSheet extends ConsumerWidget {
  const RouteComparisonSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routeProvider);
    final routes = state.availableRoutes;
    final selected = state.selectedRouteIndex;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (routes.length < 2) return const SizedBox.shrink();

    // Finds fastest route for comparison labels.
    final fastestTime = routes.map((r) => r.time).reduce((a, b) => a < b ? a : b);
    final shortestDist = routes.map((r) => r.distance).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Route', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...routes.asMap().entries.map((e) {
            final i = e.key;
            final route = e.value;
            final isSelected = i == selected;
            final isFastest = route.time == fastestTime;
            final isShortest = route.distance == shortestDist;

            // Time difference from fastest.
            final diffMin = ((route.time - fastestTime) / 60000).round();
            final diffLabel = diffMin > 0 ? ' (+${diffMin}m)' : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: InkWell(
                  onTap: () {
                    Haptics.medium();
                    ref.read(routeProvider.notifier).selectRoute(i);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Route number badge.
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? cs.onPrimary : cs.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isSelected ? cs.primary : cs.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Route info.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    route.durationFormatted,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? cs.onPrimary : cs.onSurface,
                                    ),
                                  ),
                                  if (diffLabel.isNotEmpty)
                                    Text(
                                      diffLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? cs.onPrimary.withValues(alpha: 0.7) : cs.onSurfaceVariant,
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    route.distanceFormatted,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected ? cs.onPrimary.withValues(alpha: 0.8) : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isFastest) _Badge('Fastest', cs.tertiary, isSelected),
                                  if (isShortest && !isFastest) _Badge('Shortest', cs.secondary, isSelected),
                                  Text(
                                    '${route.segments.length} segments',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? cs.onPrimary.withValues(alpha: 0.7) : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: cs.onPrimary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Small label badge for route attributes.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool inverted;
  
  const _Badge(this.label, this.color, this.inverted);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: inverted ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm / 3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: inverted ? Colors.white : color,
        ),
      ),
    );
  }
}
