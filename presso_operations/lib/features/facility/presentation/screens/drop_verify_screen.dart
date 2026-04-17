// Facility Drop-off verify screen — facility-side half of the rider→facility
// drop-off handshake. The rider hands over the bag and shows a 4-digit code
// on their phone; staff types it here and taps Verify. On success the
// backend flips the assignment to ReceivedAtFacility and the order moves
// into InProcess/AtFacility.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/facility/data/facility_repository.dart';

class DropVerifyScreen extends ConsumerStatefulWidget {
  const DropVerifyScreen({super.key});

  @override
  ConsumerState<DropVerifyScreen> createState() => _DropVerifyScreenState();
}

class _DropVerifyScreenState extends ConsumerState<DropVerifyScreen> {
  final _controllers = List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  final _focusNodes = List<FocusNode>.generate(4, (_) => FocusNode());
  bool _submitting = false;
  String? _error;
  String? _lastSuccessOrder;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_otp.length != 4 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order =
          await ref.read(facilityRepositoryProvider).verifyDrop(_otp);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _lastSuccessOrder = order.orderNumber;
      });
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified · #${order.orderNumber} received'),
          backgroundColor: PressoTokens.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Invalid or expired code';
      });
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: pressoAppBar(title: 'Drop-offs'),
      body: PhoneColumn(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PressoTokens.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            PressoTokens.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: PressoTokens.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Verify Rider Drop-off',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PressoTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask the rider for the 4-digit code shown on their '
                      'phone, then type it below to confirm you received '
                      'the bag.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: PressoTokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    _digitField(i),
                    if (i < 3) const SizedBox(width: 12),
                  ],
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PressoTokens.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_lastSuccessOrder != null && _error == null) ...[
                const SizedBox(height: 14),
                Text(
                  'Last verified: #$_lastSuccessOrder',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PressoTokens.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BtnPrimary(
                label: _submitting ? 'Verifying…' : 'Verify & Receive',
                icon: Icons.check_circle_outline,
                onPressed:
                    (_otp.length == 4 && !_submitting) ? _submit : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/facility/dashboard'),
                child: const Text(
                  'Back to Orders',
                  style: TextStyle(
                    color: PressoTokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _digitField(int i) {
    return SizedBox(
      width: 58,
      height: 68,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        autofocus: i == 0,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: PressoTokens.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: PressoTokens.primary.withValues(alpha: .06),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: PressoTokens.primary.withValues(alpha: .3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: PressoTokens.primary,
              width: 1.8,
            ),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 3) {
            _focusNodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
          setState(() {});
          if (_otp.length == 4) _submit();
        },
      ),
    );
  }
}
