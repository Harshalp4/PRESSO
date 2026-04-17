import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/loading_overlay.dart';
import 'package:presso_app/features/auth/presentation/providers/auth_provider.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final int? resendToken;
  final String? autoToken;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.resendToken,
    this.autoToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  late Timer _timer;
  int _secondsLeft = 60;
  bool get _canResend => _secondsLeft == 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == 6;

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isOtpComplete && !_isLoading) _verify();
  }

  Future<void> _verify() async {
    if (!_isOtpComplete || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var phone = widget.phone;
      if (phone.startsWith('+91')) phone = phone.substring(3);

      // Capture the router BEFORE the async login call so we can navigate
      // even after the widget is disposed by Riverpod state changes.
      final router = GoRouter.of(context);

      final container = ProviderScope.containerOf(context);
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.login(phone);

      final authState = container.read(authProvider);
      if (authState.hasError) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = authState.errorMessage ?? 'Login failed';
        });
        return;
      }

      // Cancel timer to prevent callbacks on disposed widget.
      _timer.cancel();

      // Navigate to splash — it will check auth state and route to
      // /home or /auth/setup after Riverpod state has fully settled.
      // This avoids Duplicate GlobalKey errors that happen when
      // StatefulShellRoute is built while auth state is still propagating.
      router.go('/splash');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // TODO: Replace with real Firebase resend
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isLoading = false);
    _startCountdown();
    _clearFields();
    _focusNodes[0].requestFocus();
  }

  void _clearFields() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Verifying\u2026',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 72),

                // ── Branding (same as phone auth) ──
                const Text('\u{1F45A}', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                const Text(
                  'Presso',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Premium Laundry & Care',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),

                const SizedBox(height: 44),

                // ── Enter OTP label ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Sub-label: sent to phone
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Code sent to ${_maskPhone(widget.phone)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── 6 OTP boxes (teal border, centered, mockup style) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final hasFocus = _focusNodes[index].hasFocus;
                    final hasValue = _controllers[index].text.isNotEmpty;
                    return Padding(
                      padding: EdgeInsets.only(right: index < 5 ? 8.0 : 0),
                      child: SizedBox(
                        width: 46,
                        height: 52,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          cursorColor: AppColors.primary,
                          onChanged: (v) => _onDigitChanged(index, v),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: hasValue ? null : '_',
                            hintStyle: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            fillColor: AppColors.surface,
                            filled: true,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: hasFocus || hasValue
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: hasValue
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // ── Error ──
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.red,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Resend countdown ──
                GestureDetector(
                  onTap: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend ? 'Resend code' : 'Resend in ${_secondsLeft}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: _canResend
                          ? AppColors.primary
                          : AppColors.textHint,
                      fontWeight:
                          _canResend ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Verify button (gradient) ──
                _GradientButton(
                  label: 'Verify',
                  onPressed: _isOtpComplete ? _verify : null,
                ),

                const SizedBox(height: 24),

                // ── Help text ──
                const Text(
                  'Didn\'t receive code? Check if number is correct',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.startsWith('+91') && phone.length == 13) {
      final digits = phone.substring(3);
      return '+91 ${digits.substring(0, 2)}XXX XX${digits.substring(7)}';
    }
    return phone;
  }
}

// ─── Gradient CTA button (shared style) ──────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GradientButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isActive = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : AppColors.border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0891B2).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
