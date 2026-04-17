import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'presso_button.dart';

/// A reusable empty state widget with an icon, title, subtitle, and optional action button.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconColor = AppColors.textSecondary,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.customIllustration,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  /// An optional custom widget to replace the default icon container (e.g. Lottie animation).
  final Widget? customIllustration;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration / Icon
            customIllustration ??
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 44),
                ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: PressoButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  type: PressoButtonType.primary,
                  height: 44,
                  icon: actionIcon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preconfigured variants
// ---------------------------------------------------------------------------

/// Empty state for order lists.
class EmptyOrdersWidget extends StatelessWidget {
  const EmptyOrdersWidget({super.key, this.onBookNow});

  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.local_laundry_service_outlined,
      iconColor: AppColors.primary,
      title: 'No Orders Yet',
      subtitle: 'Place your first order and enjoy fresh laundry at your doorstep!',
      actionLabel: onBookNow != null ? 'Book Now' : null,
      actionIcon: Icons.add_rounded,
      onAction: onBookNow,
    );
  }
}

/// Empty state for address lists.
class EmptyAddressesWidget extends StatelessWidget {
  const EmptyAddressesWidget({super.key, this.onAddAddress});

  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.location_off_outlined,
      iconColor: AppColors.amber,
      title: 'No Addresses Found',
      subtitle: 'Add your address to get started with doorstep delivery.',
      actionLabel: onAddAddress != null ? 'Add Address' : null,
      actionIcon: Icons.add_location_alt_outlined,
      onAction: onAddAddress,
    );
  }
}

/// Empty state for notification lists.
class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_rounded,
      iconColor: AppColors.purple,
      title: "You're All Caught Up!",
      subtitle: 'No new notifications right now.',
    );
  }
}
