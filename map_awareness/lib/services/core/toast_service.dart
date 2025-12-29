import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Service wrapper for displaying toast notifications using toastification package.
class ToastService {
  ToastService._();

  static void success(BuildContext context, String message) {
    _show(context, message, ToastificationType.success, Colors.green);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, ToastificationType.error, Theme.of(context).colorScheme.error);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, ToastificationType.warning, Colors.orange);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, ToastificationType.info, Theme.of(context).colorScheme.primary);
  }

  /// Internal helper to show a toast with specific type and color configuration.
  static void _show(BuildContext context, String message, ToastificationType type, Color color) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomCenter,
      primaryColor: color,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      boxShadow: AppTheme.cardShadow(context),
    );
  }
}
