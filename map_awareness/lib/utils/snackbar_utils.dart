import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_awareness/utils/app_theme.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar(String message, {Color? color, Duration? duration}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: ExcludeSemantics(
          child: Row(
            children: [
              if (color != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForColor(color),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color ?? AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration ?? const Duration(milliseconds: 3000),
        elevation: 8,
      ),
    );
  }
  
  IconData _getIconForColor(Color color) {
    if (color == AppTheme.success) return Icons.check_circle_rounded;
    if (color == AppTheme.error) return Icons.error_rounded;
    if (color == AppTheme.warning) return Icons.warning_rounded;
    if (color == AppTheme.info) return Icons.info_rounded;
    return Icons.notifications_rounded;
  }
}
