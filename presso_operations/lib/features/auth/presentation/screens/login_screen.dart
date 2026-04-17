import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneController.text.length < 10) {
      _showError('Enter a valid 10-digit phone number');
      return;
    }
    setState(() => _otpSent = true);
    _otpFocus.requestFocus();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.length < 10) {
      _showError('Enter a valid phone number');
      return;
    }
    if (otp.length != 4) {
      _showError('Enter a 4-digit OTP');
      return;
    }

    await ref.read(authProvider.notifier).login(phone, otp);
    if (!mounted) return;

    final state = ref.read(authProvider);
    if (state.error != null) {
      _showError(state.error!);
      return;
    }
    if (state.isAuthenticated) {
      _navigateByRole(state.role);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateByRole(String? role) {
    switch (role) {
      case 'Rider':
        context.go('/rider/dashboard');
      case 'FacilityStaff':
        context.go('/facility/dashboard');
      default:
        _showError('Access denied. Only Rider and Facility Staff can use this app.');
        ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  // ── Logo ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Presso Operations',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rider & Facility Staff Portal',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Phone input card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otpSent ? 'VERIFY OTP' : 'SIGN IN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            enabled: !_otpSent,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: TextStyle(color: AppColors.textHint),
                              prefixText: '+91  ',
                              prefixStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 4),
                                child: Icon(Icons.phone_outlined,
                                    color: AppColors.primary, size: 20),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 40),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onSubmitted: (_) =>
                                _otpSent ? _otpFocus.requestFocus() : _sendOtp(),
                          ),
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 12),

                          // OTP field
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _otpController,
                              focusNode: _otpFocus,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 4,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: InputDecoration(
                                hintText: '0000',
                                hintStyle: TextStyle(
                                  color: AppColors.textHint,
                                  letterSpacing: 4,
                                ),
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 14, right: 4),
                                  child: Icon(Icons.lock_outline_rounded,
                                      color: AppColors.primary, size: 20),
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(minWidth: 40),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Login / Send OTP button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: authState.isLoading
                                ? null
                                : (_otpSent ? _login : _sendOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _otpSent ? 'Login' : 'Send OTP',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: Text(
                                'Change phone number',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Dev hint (subtle) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.amber.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Test Accounts',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rider: 8888888888  \u2022  Facility: 7777777777\nAny 4-digit OTP works',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
