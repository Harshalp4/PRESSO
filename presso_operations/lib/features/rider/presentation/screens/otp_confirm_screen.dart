import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';

class OtpConfirmScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final int count;
  final String? notes;
  final int photosTaken;

  const OtpConfirmScreen({
    super.key,
    required this.assignmentId,
    required this.count,
    this.notes,
    this.photosTaken = 0,
  });

  @override
  ConsumerState<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends ConsumerState<OtpConfirmScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const int _otpLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _focusNode.addListener(() => setState(() {}));
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submitOtp() async {
    final otp = _controller.text;
    if (otp.length != _otpLength) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(riderRepositoryProvider).confirmPickup(
            assignmentId: widget.assignmentId,
            otp: otp,
            count: widget.count,
            notes: widget.notes,
          );
      if (mounted) {
        context.go(
          '/rider/job/${widget.assignmentId}/complete',
          extra: {
            'count': widget.count,
            'photosTaken': widget.photosTaken,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Incorrect OTP';
        _isSubmitting = false;
      });
      _shakeController.forward(from: 0);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Customer OTP',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            children: [
              _buildInstructionCard(),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final dx = _shakeAnimation.value *
                      10 *
                      ((_shakeController.value * 8).round().isEven ? 1 : -1);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: _buildOtpInput(),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (_isSubmitting) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Verifying OTP...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Manual verify button as a fallback in case auto-submit
              // doesn't trigger (e.g. user pastes a partial code).
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Ask customer to show OTP\nfrom their Presso app',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 4-digit code shown on their screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visible boxes showing current digits
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_otpLength, (index) {
              final text = _controller.text;
              final hasDigit = index < text.length;
              final isCurrent =
                  _focusNode.hasFocus && index == text.length;
              return Container(
                width: 60,
                height: 68,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.red.withOpacity(0.5)
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.border,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasDigit ? text[index] : '',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          // Single invisible TextField drives input
          SizedBox(
            width: (60 + 16) * _otpLength.toDouble(),
            height: 68,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: _otpLength,
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 1,
                height: 0,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                setState(() => _errorMessage = null);
                if (value.length == _otpLength) {
                  _submitOtp();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
