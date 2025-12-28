import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:map_awareness/utils/app_theme.dart';

/// Standard shimmer loading effect
class LoadingShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const LoadingShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceContainerHigh,
      highlightColor: Colors.white,
      child: IgnorePointer(child: child),
    );
  }
}

/// Helper to create a shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
