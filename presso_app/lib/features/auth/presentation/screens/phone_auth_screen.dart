import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/config/env_config.dart';
import 'package:presso_app/core/widgets/loading_overlay.dart';
import 'package:presso_app/features/auth/presentation/providers/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  // OTP state
  bool _otpSent = false;
  String _phone = '';
  Timer? _timer;
  int _secondsLeft = 30;
  bool get _canResend => _secondsLeft == 0;

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;
  String get _otpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == 4;

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Send OTP ────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _phone = '+91${_phoneController.text.trim()}';

    // TODO: Replace with real Firebase phone auth
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
    _startCountdown();
    // Focus first OTP box
    _otpFocusNodes[0].requestFocus();
  }

  // ── Countdown ───────────────────────────────────────────────────────────────

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = 30;
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

  // ── OTP digit handling ──────────────────────────────────────────────────────

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isOtpComplete) _verify();
  }

  // ── Verify ──────────────────────────────────────────────────────────────────

  Future<void> _verify() async {
    if (!_isOtpComplete) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var phone = _phone;
      if (phone.startsWith('+91')) phone = phone.substring(3);

      // Access provider container directly — avoids ConsumerStatefulElement
      // lifecycle entanglement that causes "Duplicate GlobalKey" crashes.
      final container = ProviderScope.containerOf(context);
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.login(phone);

      if (!mounted) return;

      final authState = container.read(authProvider);
      if (authState.hasError) {
        setState(() {
          _isLoading = false;
          _errorMessage = authState.errorMessage ?? 'Login failed';
        });
        return;
      }

      // Compute destination before scheduling navigation.
      final hasName =
          authState.user?.name != null && authState.user!.name!.isNotEmpty;
      final destination = hasName ? '/home' : '/auth/setup';

      // Schedule navigation on the NEXT event-loop iteration so that all
      // synchronous Riverpod notifications and widget-tree updates finish
      // before GoRouter restructures the tree.
      Future(() {
        if (mounted) context.go(destination);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again.';
      });
    }
  }

  // ── Resend ──────────────────────────────────────────────────────────────────

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
    for (final c in _otpControllers) {
      c.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: _otpSent ? 'Verifying\u2026' : 'Sending OTP\u2026',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ── Branding ──
                const Text('\u{1F45A}', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text(
                  'Presso',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Premium Laundry & Care',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),

                const SizedBox(height: 40),

                // ── Phone entry section ──
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter phone number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // +91 + phone field
                Row(
                  children: [
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          autofocus: !_otpSent,
                          enabled: !_otpSent,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _isPhoneValid ? _sendOtp() : null,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                            fillColor: AppColors.surface,
                            filled: true,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 1.5),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Send OTP button ──
                _GradientButton(
                  label: 'Send OTP',
                  onPressed: _isPhoneValid && !_otpSent ? _sendOtp : null,
                ),

                const SizedBox(height: 16),

                // ── Firebase note ──
                const Text(
                  'Firebase Phone Authentication',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),

                // ── OTP Section (appears after Send OTP) ──
                if (_otpSent) ...[
                  const SizedBox(height: 32),

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
                  const SizedBox(height: 12),

                  // 4 OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final hasValue = _otpControllers[index].text.isNotEmpty;
                      return Padding(
                        padding: EdgeInsets.only(right: index < 3 ? 10.0 : 0),
                        child: SizedBox(
                          width: 50,
                          height: 54,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
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
                            onChanged: (v) => _onOtpDigitChanged(index, v),
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
                                  color: hasValue
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

                  const SizedBox(height: 16),

                  // Resend countdown
                  GestureDetector(
                    onTap: _canResend ? _resendOtp : null,
                    child: Text(
                      _canResend
                          ? 'Resend code'
                          : 'Resend in ${_secondsLeft}s',
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
                ],

                // ── Error ──
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.red,
                      fontSize: 12,
                    ),
                  ),
                ],

                // ── Terms (only before OTP sent) ──
                if (!_otpSent) ...[
                  const SizedBox(height: 48),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'By continuing you agree to our Terms of Service & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                // ── API Environment Toggle (debug only) ──
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  _buildEnvToggle(),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvToggle() {
    final env = ref.watch(envConfigProvider);
    final isLocal = env == ApiEnvironment.local;

    return GestureDetector(
      onTap: () => ref.read(envConfigProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isLocal
              ? AppColors.amber.withOpacity(0.1)
              : AppColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocal
                ? AppColors.amber.withOpacity(0.3)
                : AppColors.green.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocal ? Icons.computer : Icons.cloud,
              size: 14,
              color: isLocal ? AppColors.amber : AppColors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'API: ${env.label}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLocal ? AppColors.amber : AppColors.green,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.swap_horiz,
              size: 14,
              color: isLocal ? AppColors.amber : AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient CTA button ─────────────────────────────────────────────────────

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
