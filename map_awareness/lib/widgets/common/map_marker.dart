import 'package:flutter/material.dart';
import 'package:map_awareness/utils/helpers.dart';

/// Circular map marker widget with customizable colors and tap behavior.
class MapMarker extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const MapMarker({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.onTap,
  });

  /// Creates a smaller, inverted color variant for secondary or clustered markers.
  const MapMarker.small({
    super.key,
    required this.icon,
    required Color color,
  }) : backgroundColor = Colors.white, foregroundColor = color, onTap = null;

  @override
  Widget build(BuildContext context) {
    final isSmall = backgroundColor == Colors.white;
    
    final container = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: !isSmall ? Border.all(color: Colors.white, width: 1.5) : null,
        boxShadow: isSmall ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)] : null,
      ),
      child: Icon(icon, color: foregroundColor, size: isSmall ? 18 : 14),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          Haptics.select();
          onTap!();
        },
        child: container,
      );
    }
    return container;
  }
}
