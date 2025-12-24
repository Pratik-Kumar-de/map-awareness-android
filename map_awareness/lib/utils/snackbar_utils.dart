import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar(String message, {Color? color, bool floating = false, Duration? duration}) {
    // On Windows, the automatic SnackBar announcement often triggers a 'viewId' error in logs.
    // We manually dispatch a semantic announcement associated with the current view.
    final view = View.of(this);
    
    // Use the modern sendAnnouncement method which is preferred in multi-window environments
    SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.of(this),
    );

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        // We use ExcludeSemantics on the content to prevent the framework's own 
        // (broken) announcement on Windows, while our manual event handles it correctly.
        content: ExcludeSemantics(child: Text(message)),
        backgroundColor: color,
        behavior: floating ? SnackBarBehavior.floating : null,
        duration: duration ?? const Duration(milliseconds: 4000),
      ),
    );
  }
}
