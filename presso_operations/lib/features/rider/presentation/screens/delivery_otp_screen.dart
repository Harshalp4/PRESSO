import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';

class DeliveryOtpScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const DeliveryOtpScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends ConsumerState<DeliveryOtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isComplete = false;
  late AnimationController _shakeController;

  static const int _otpLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
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
      await ref.read(riderRepositoryProvider).confirmDelivery(
            assignmentId: widget.assignmentId,
            otp: otp,
          );
      if (mounted) {
        setState(() => _isComplete = true);
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
    if (_isComplete) {
      return _buildDeliveryCompleteView();
    }

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 1),
            _buildInstructionCard(),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = _shakeController.value *
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
              const CircularProgressIndicator(color: AppColors.green),
              const SizedBox(height: 12),
              Text(
                'Verifying OTP...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.green, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Ask customer to show OTP\nfrom their Presso app',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
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
                            ? AppColors.green
                            : AppColors.border,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasDigit ? text[index] : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
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

  Widget _buildDeliveryCompleteView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.green,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The order has been delivered successfully.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on,
                              color: AppColors.amber, size: 28),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coins Awarded!',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Delivery earnings will be credited',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/rider/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
