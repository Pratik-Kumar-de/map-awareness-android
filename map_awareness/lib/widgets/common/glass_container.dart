import 'dart:ui';
import 'package:flutter/material.dart';

/// Container widget that implements a glassmorphism effect using BackdropFilter and semi-transparent layers.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.borderRadius = 12,
    this.blur = 8,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Theme-aware defaults.
    final effectiveColor = color ?? (isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7));
    final effectiveBorder = borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12));

    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder),
      ),
      child: child,
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: onTap != null
            ? Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: () => onTap!(), borderRadius: BorderRadius.circular(borderRadius), child: box),
              )
            : box,
      ),
    );

    return margin != null ? Padding(padding: margin!, child: glass) : glass;
  }
}
