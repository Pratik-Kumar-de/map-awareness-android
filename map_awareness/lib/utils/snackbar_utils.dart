import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar(String message, {Color? color, bool floating = false, Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        // ExcludeSemantics prevents the Windows 'viewId' accessibility error
        content: ExcludeSemantics(child: Text(message)),
        backgroundColor: color,
        behavior: floating ? SnackBarBehavior.floating : null,
        duration: duration ?? const Duration(milliseconds: 4000),
      ),
    );
  }
}
