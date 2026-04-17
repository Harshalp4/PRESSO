import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

enum PressoButtonType { primary, outline, ghost, danger }

class PressoButton extends StatelessWidget {
  const PressoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = PressoButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 48,
    this.borderRadius = 10,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final PressoButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  bool get _isInteractive => !isDisabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (type) {
      case PressoButtonType.primary:
        return _PrimaryButton(
          label: label,
          onPressed: _isInteractive ? onPressed : null,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          trailingIcon: trailingIcon,
          borderRadius: borderRadius,
          padding: padding,
        );
      case PressoButtonType.outline:
        return _OutlineButton(
          label: label,
          onPressed: _isInteractive ? onPressed : null,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          trailingIcon: trailingIcon,
          borderRadius: borderRadius,
          padding: padding,
        );
      case PressoButtonType.ghost:
        return _GhostButton(
          label: label,
          onPressed: _isInteractive ? onPressed : null,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          trailingIcon: trailingIcon,
          borderRadius: borderRadius,
          padding: padding,
        );
      case PressoButtonType.danger:
        return _DangerButton(
          label: label,
          onPressed: _isInteractive ? onPressed : null,
          isLoading: isLoading,
          isDisabled: isDisabled,
          icon: icon,
          trailingIcon: trailingIcon,
          borderRadius: borderRadius,
          padding: padding,
        );
    }
  }
}

// =============================================================================
// Primary Button — cyan gradient fill
// =============================================================================

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    required this.isLoading,
    required this.isDisabled,
    this.icon,
    this.trailingIcon,
    required this.borderRadius,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  bool get _inactive => isDisabled || (onPressed == null && !isLoading);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _inactive
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _inactive ? AppColors.border : null,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _ButtonContent(
              label: label,
              isLoading: isLoading,
              icon: icon,
              trailingIcon: trailingIcon,
              textColor:
                  _inactive ? AppColors.textSecondary : AppColors.background,
              loadingColor: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Outline Button — transparent with cyan border
// =============================================================================

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    this.onPressed,
    required this.isLoading,
    required this.isDisabled,
    this.icon,
    this.trailingIcon,
    required this.borderRadius,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDisabled ? AppColors.textHint : AppColors.primary;
    final textColor = isDisabled ? AppColors.textHint : AppColors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.06),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _ButtonContent(
              label: label,
              isLoading: isLoading,
              icon: icon,
              trailingIcon: trailingIcon,
              textColor: textColor,
              loadingColor: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Ghost Button — transparent with cyan text
// =============================================================================

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    this.onPressed,
    required this.isLoading,
    required this.isDisabled,
    this.icon,
    this.trailingIcon,
    required this.borderRadius,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textColor = isDisabled ? AppColors.textHint : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.06),
        child: Padding(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: _ButtonContent(
            label: label,
            isLoading: isLoading,
            icon: icon,
            trailingIcon: trailingIcon,
            textColor: textColor,
            loadingColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Danger Button — red fill
// =============================================================================

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    this.onPressed,
    required this.isLoading,
    required this.isDisabled,
    this.icon,
    this.trailingIcon,
    required this.borderRadius,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  bool get _inactive => isDisabled || (onPressed == null && !isLoading);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _inactive ? AppColors.border : AppColors.red,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: _ButtonContent(
              label: label,
              isLoading: isLoading,
              icon: icon,
              trailingIcon: trailingIcon,
              textColor: _inactive
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              loadingColor: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared button content
// =============================================================================

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    this.icon,
    this.trailingIcon,
    required this.textColor,
    required this.loadingColor,
  });

  final String label;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color textColor;
  final Color loadingColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(color: textColor),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, color: textColor, size: 18),
        ],
      ],
    );
  }
}
