import 'package:flutter/material.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Premium empty state with animated illustration
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional action
            if (action != null) ...[
              const SizedBox(height: 28),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
