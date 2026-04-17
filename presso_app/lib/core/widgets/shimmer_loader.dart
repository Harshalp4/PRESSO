import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

// =============================================================================
// Core ShimmerLoader wrapper
// =============================================================================

/// Wraps any [child] widget with a shimmer animation.
/// Use for loading placeholders to indicate in-progress content loading.
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: baseColor ?? AppColors.surfaceLight,
      highlightColor: highlightColor ?? AppColors.border.withOpacity(0.6),
      child: child,
    );
  }
}

// =============================================================================
// Reusable shimmer primitives
// =============================================================================

/// A rounded rectangle shimmer block, useful as a placeholder for text or images.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular shimmer placeholder, useful for avatars and icons.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// ShimmerCard — generic card placeholder
// =============================================================================

/// A single shimmer card placeholder.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 100,
    this.margin,
    this.borderRadius = 12,
  });

  final double height;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// =============================================================================
// ShimmerList — a column of shimmer cards
// =============================================================================

/// Renders [count] shimmer card placeholders in a column, useful while
/// a list is loading.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 90,
    this.padding,
    this.cardBorderRadius = 12,
  });

  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: List.generate(
          count,
          (index) => ShimmerCard(
            height: itemHeight,
            borderRadius: cardBorderRadius,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ShimmerOrderCard — order list item placeholder
// =============================================================================

class ShimmerOrderCard extends StatelessWidget {
  const ShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: order number + status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerBox(width: 100, height: 14),
                ShimmerBox(
                  width: 70,
                  height: 24,
                  borderRadius: 12,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Service name
            const ShimmerBox(width: 140, height: 16),
            const SizedBox(height: 8),
            // Date + price row
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 120, height: 12),
                ShimmerBox(width: 60, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ShimmerServiceCard — service grid item placeholder
// =============================================================================

class ShimmerServiceCard extends StatelessWidget {
  const ShimmerServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerCircle(size: 44),
            SizedBox(height: 12),
            ShimmerBox(width: 80, height: 14),
            SizedBox(height: 6),
            ShimmerBox(width: 60, height: 12),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ShimmerProfile — profile screen placeholder
// =============================================================================

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name section
            Row(
              children: [
                const ShimmerCircle(size: 72),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 140, height: 18),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 13),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Info rows
            for (int i = 0; i < 4; i++) ...[
              const ShimmerBox(width: double.infinity, height: 52, borderRadius: 10),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
