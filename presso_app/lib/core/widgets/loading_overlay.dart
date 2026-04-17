import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Wraps a [child] widget and optionally shows a full-screen semi-transparent
/// loading overlay with a [CircularProgressIndicator] in the primary color.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: _OverlayContent(
              message: message,
              barrierColor: barrierColor,
            ),
          ),
      ],
    );
  }
}

/// A standalone full-screen loading screen (useful as a route-level overlay).
class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: _LoadingCard(message: message),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({this.message, this.barrierColor});

  final String? message;
  final Color? barrierColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: barrierColor ?? Colors.black.withOpacity(0.55),
      child: Center(
        child: _LoadingCard(message: message),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
