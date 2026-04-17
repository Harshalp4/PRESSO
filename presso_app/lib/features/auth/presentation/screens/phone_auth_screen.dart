import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fb;
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

/// Desktop platforms don't support Firebase Phone Auth at all.
bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  // OTP state
  bool _otpSent = false;
  String _phone = '';
  Timer? _timer;
  int _secondsLeft = 30;
  bool get _canResend => _secondsLeft == 0;

  // Firebase Phone Auth state
  String? _verificationId;
  int? _resendToken;

  bool get _isPhoneValid => _phoneController.text.trim().length == 10;
  String get _otpCode => _otpControllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpCode.length == 6;

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

  Future<void> _sendOtp({int? forceResendToken}) async {
    if (!_isPhoneValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _phone = '+91${_phoneController.text.trim()}';

    // Use dummy OTP when: desktop (unsupported) OR Firebase auth toggle is off
    final useFirebase = ref.read(useFirebaseAuthProvider);
    if (_isDesktop || !useFirebase) {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      _startCountdown();
      // Delay focus so the OTP fields are rendered before requesting keyboard
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
      return;
    }

    await fb.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phone,
      forceResendingToken: forceResendToken,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-verification (Android only) — sign in immediately
        await _signInWithCredential(credential);
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.message ?? 'Failed to send OTP';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        _verificationId = verificationId;
        _resendToken = resendToken;
        setState(() {
          _isLoading = false;
          _otpSent = true;
        });
        _startCountdown();
        _otpFocusNodes[0].requestFocus();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
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
    if (value.length == 1 && index < 5) {
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

    // Dummy OTP: skip Firebase, send phone number directly (API DevAuth mode)
    final useFirebase = ref.read(useFirebaseAuthProvider);
    if (_isDesktop || !useFirebase) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final container = ProviderScope.containerOf(context);
        final authNotifier = container.read(authProvider.notifier);
        // In DevAuth mode the API treats firebaseToken as the phone number
        await authNotifier.login(_phone);

        if (!mounted) return;
        final authState = container.read(authProvider);
        if (authState.hasError) {
          setState(() {
            _isLoading = false;
            _errorMessage = authState.errorMessage ?? 'Login failed';
          });
          return;
        }
        final hasName =
            authState.user?.name != null && authState.user!.name!.isNotEmpty;
        final destination = hasName ? '/home' : '/auth/setup';
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
      return;
    }

    if (_verificationId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCode,
      );
      await _signInWithCredential(credential);
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'invalid-verification-code':
          msg = 'Invalid OTP. Please try again.';
          break;
        case 'session-expired':
          msg = 'OTP expired. Please resend.';
          break;
        default:
          msg = e.message ?? 'Verification failed';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed. Please try again.';
      });
    }
  }

  Future<void> _signInWithCredential(fb.PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to get Firebase token';
          });
        }
        return;
      }

      // Exchange Firebase ID token for Presso JWT
      final container = ProviderScope.containerOf(context);
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.login(idToken);

      if (!mounted) return;

      final authState = container.read(authProvider);
      if (authState.hasError) {
        setState(() {
          _isLoading = false;
          _errorMessage = authState.errorMessage ?? 'Login failed';
        });
        return;
      }

      final hasName =
          authState.user?.name != null && authState.user!.name!.isNotEmpty;
      final destination = hasName ? '/home' : '/auth/setup';

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
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() => _otpSent = false);
    await _sendOtp(forceResendToken: _resendToken);
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

                // ── Auth mode note ──
                Builder(builder: (context) {
                  final firebaseOn = ref.watch(useFirebaseAuthProvider);
                  final isDummy = _isDesktop || !firebaseOn;
                  return Text(
                    isDummy
                        ? 'Dev Mode (any 6-digit OTP)'
                        : 'Firebase Phone Authentication',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  );
                }),

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

                  // 6 OTP boxes (Firebase uses 6-digit codes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final hasValue = _otpControllers[index].text.isNotEmpty;
                      return Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 8.0 : 0),
                        child: SizedBox(
                          width: 44,
                          height: 52,
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

                // ── Debug toggles (debug only) ──
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEnvToggle(),
                      const SizedBox(width: 10),
                      _buildFirebaseAuthToggle(),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirebaseAuthToggle() {
    final firebaseOn = ref.watch(useFirebaseAuthProvider);

    return GestureDetector(
      onTap: () => ref.read(useFirebaseAuthProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: firebaseOn
              ? AppColors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: firebaseOn
                ? AppColors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              firebaseOn ? Icons.verified_user : Icons.bug_report,
              size: 14,
              color: firebaseOn ? AppColors.green : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              firebaseOn ? 'OTP: Real' : 'OTP: Dummy',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: firebaseOn ? AppColors.green : Colors.grey,
              ),
            ),
          ],
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
