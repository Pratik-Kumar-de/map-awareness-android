import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glass-morphism container for overlays
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.borderRadius = 12,
    this.blur = 8,
    this.color = const Color(0xB3FFFFFF), // white with 0.7 alpha roughly
    this.borderColor = const Color(0x33000000),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: onTap != null
            ? InkWell(onTap: () => onTap!(), borderRadius: BorderRadius.circular(borderRadius), child: box)
            : box,
      ),
    );

    return margin != null ? Padding(padding: margin!, child: glass) : glass;
  }
}
