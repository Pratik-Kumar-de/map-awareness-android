import 'package:flutter/material.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Standard sheet for displaying map object details
class MapDetailsSheet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String description;
  final List<Widget>? additionalChips;

  const MapDetailsSheet({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.additionalChips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use simple container to prevent full-screen blocking by DraggableScrollableSheet
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              if (additionalChips != null && additionalChips!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: additionalChips!,
                  ),
                ),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
