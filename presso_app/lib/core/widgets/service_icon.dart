import 'package:flutter/material.dart';

/// A shared widget that renders a service or garment icon from DB data.
///
/// Priority: emoji (from DB) → iconUrl (network image) → fallback icon.
/// Used across service selection, garment count, order summary, treatment
/// screens, and the ops app to guarantee visual consistency.
class ServiceIcon extends StatelessWidget {
  final String? emoji;
  final String? iconUrl;
  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;

  const ServiceIcon({
    super.key,
    this.emoji,
    this.iconUrl,
    this.size = 48,
    this.backgroundColor,
    this.borderRadius = 11,
    this.fallbackIcon = Icons.local_laundry_service_rounded,
    this.fallbackIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // 1. Emoji from DB (highest priority)
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(
        emoji!,
        style: TextStyle(fontSize: size * 0.45),
      );
    }

    // 2. Network image (iconUrl from DB — for future use)
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.7),
        child: Image.network(
          iconUrl!,
          width: size * 0.65,
          height: size * 0.65,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }

    // 3. Fallback Material icon
    return _fallback();
  }

  Widget _fallback() {
    return Icon(
      fallbackIcon,
      size: size * 0.45,
      color: fallbackIconColor ?? Colors.white70,
    );
  }
}

/// Convenience widget specifically for garment items.
/// Smaller default size, reads emoji from GarmentTypeModel data.
class GarmentIcon extends StatelessWidget {
  final String? emoji;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const GarmentIcon({
    super.key,
    this.emoji,
    this.size = 36,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (emoji != null && emoji!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji!,
          style: TextStyle(fontSize: size * 0.55),
        ),
      );
    }

    // No emoji — show a subtle placeholder
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom_rounded,
        size: size * 0.5,
        color: textColor ?? Colors.grey,
      ),
    );
  }
}
