import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


/// Wrapper widget applying a linear shimmer animation to its child for loading states.
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

    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surface,
      child: IgnorePointer(child: child),
    );
  }
}

/// Placeholder container representing a loading block element.
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Reusable skeleton card for consistent loading states.
class SkeletonCard extends StatelessWidget {
  final double height;
  final double radius;

  const SkeletonCard({super.key, this.height = 100, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Common loading skeleton layouts.
class SkeletonLayouts {
  /// Standard content loading skeleton.
  static Widget content() => const LoadingShimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonCard(height: 100),
        SizedBox(height: 16),
        SkeletonCard(height: 150),
      ],
    ),
  );

  /// Warnings screen loading skeleton.
  static Widget warnings() => const LoadingShimmer(
    child: Column(
      children: [
        SkeletonCard(height: 120),
        SizedBox(height: 20),
        SkeletonCard(height: 80),
        SizedBox(height: 20),
        SkeletonCard(height: 200),
      ],
    ),
  );
}
