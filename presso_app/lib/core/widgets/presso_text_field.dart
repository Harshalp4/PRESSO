import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class PressoTextField extends StatefulWidget {
  const PressoTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.prefixWidget,
    this.suffixWidget,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.focusNode,
    this.textInputAction,
    this.errorText,
    this.contentPadding,
    this.fillColor,
    this.enabled = true,
    this.initialValue,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? errorText;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool enabled;
  final String? initialValue;
  final TextCapitalization textCapitalization;

  @override
  State<PressoTextField> createState() => _PressoTextFieldState();
}

class _PressoTextFieldState extends State<PressoTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscure() => setState(() => _obscureText = !_obscureText);

  Widget? get _suffixWidget {
    // If the field is a password field, always show toggle icon
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: _toggleObscure,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );
    }
    // Custom suffix widget takes precedence
    if (widget.suffixWidget != null) return widget.suffixWidget;
    // Then suffix icon
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: AppColors.textSecondary, size: 20),
        onPressed: widget.onSuffixTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      );
    }
    return null;
  }

  Widget? get _prefixWidget {
    if (widget.prefixWidget != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: widget.prefixWidget,
      );
    }
    if (widget.prefixIcon != null) {
      return Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 20);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          enabled: widget.enabled,
          textCapitalization: widget.textCapitalization,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
            fillColor: widget.fillColor ?? AppColors.surface,
            filled: true,
            counterText: '',
            errorText: widget.errorText,
            errorStyle: AppTextStyles.caption.copyWith(color: AppColors.red),
            errorMaxLines: 2,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
            prefixIcon: _prefixWidget,
            prefixIconConstraints: widget.prefixIcon != null
                ? const BoxConstraints(minWidth: 48, minHeight: 48)
                : widget.prefixWidget != null
                    ? const BoxConstraints(minWidth: 0)
                    : null,
            suffixIcon: _suffixWidget,
          ),
        ),
      ],
    );
  }
}
