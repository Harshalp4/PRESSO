import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'presso_button.dart';

/// A reusable error state widget with an icon, message, and optional retry button.
class PressoErrorWidget extends StatelessWidget {
  const PressoErrorWidget({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.icon = Icons.error_outline_rounded,
    this.iconColor = AppColors.red,
    this.title,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final String? title;
  final String retryLabel;
  final VoidCallback? onRetry;

  /// When [compact] is true, renders a smaller inline version without padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactError(message: message, onRetry: onRetry);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 160,
                child: PressoButton(
                  label: retryLabel,
                  onPressed: onRetry,
                  type: PressoButtonType.outline,
                  height: 44,
                  icon: Icons.refresh_rounded,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline error widget for use inside cards or lists.
class _CompactError extends StatelessWidget {
  const _CompactError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.red),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A convenience widget for network-related errors.
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PressoErrorWidget(
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.amber,
      title: 'No Internet Connection',
      message:
          'Please check your internet connection and try again.',
      onRetry: onRetry,
    );
  }
}
