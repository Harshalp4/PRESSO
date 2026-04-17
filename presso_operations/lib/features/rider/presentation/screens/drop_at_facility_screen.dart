// Drop at Facility screen — two-sided OTP handshake (wireframe screen 7).
//
// The rider has already picked up the bag (assignment is InTransitToFacility)
// and is now at the facility. Tapping "Start Drop" calls
// POST /api/riders/me/job/{id}/start-drop, which returns a 4-digit OTP with a
// 5-minute TTL. The rider shows the code to facility staff, who types it into
// the facility app's drop-off screen (POST /api/facility/drop/verify). When
// the backend flips the assignment to ReceivedAtFacility, this screen polls
// /me/job/{id} and auto-closes back to the dashboard.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/rider_provider.dart';

class DropAtFacilityScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const DropAtFacilityScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<DropAtFacilityScreen> createState() =>
      _DropAtFacilityScreenState();
}

class _DropAtFacilityScreenState
    extends ConsumerState<DropAtFacilityScreen> {
  AssignmentModel? _assignment;
  DropOtpModel? _otp;
  bool _loading = true;
  bool _starting = false;
  String? _error;

  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final a = await ref
          .read(riderRepositoryProvider)
          .getJobDetail(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _assignment = a;
        _loading = false;
      });
      // If the facility already verified in a previous session the
      // assignment will be ReceivedAtFacility; bounce back to the dashboard.
      if (a.status == 'ReceivedAtFacility') {
        _onVerified();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load assignment';
        _loading = false;
      });
    }
  }

  Future<void> _startDrop() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final otp = await ref
          .read(riderRepositoryProvider)
          .startDrop(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _otp = otp;
        _secondsRemaining = otp.secondsRemaining;
        _starting = false;
      });
      _startCountdown();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Failed to generate drop code. Try again.';
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining = _secondsRemaining > 0 ? _secondsRemaining - 1 : 0;
      });
      if (_secondsRemaining == 0) {
        _countdownTimer?.cancel();
      }
    });
  }

  /// Poll the assignment every 3s so the screen auto-closes as soon as
  /// facility staff verifies the OTP. 100 ticks = 5 minutes, matching the
  /// OTP TTL.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final a = await ref
            .read(riderRepositoryProvider)
            .getJobDetail(widget.assignmentId);
        if (!mounted) return;
        if (a.status == 'ReceivedAtFacility') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          _onVerified();
        }
      } catch (_) {
        // Ignore transient errors — next tick will retry.
      }
    });
  }

  void _onVerified() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facility verified the drop. Nice work!'),
        backgroundColor: PressoTokens.green,
      ),
    );
    // Refresh the dashboard list so the card disappears immediately.
    ref.read(riderProvider.notifier).loadJobs();
    context.go('/rider/dashboard');
  }

  void _navigate() {
    final address = _assignment?.address?.addressLine1 ?? 'Presso facility';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatMmSs(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PressoTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Drop at Facility',
          style: TextStyle(
            color: PressoTokens.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: PhoneColumn(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: PressoTokens.primary),
              )
            : _assignment == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error ?? 'Assignment not found',
                        style: const TextStyle(
                            color: PressoTokens.textSecondary),
                      ),
                    ),
                  )
                : _content(),
      ),
    );
  }

  Widget _content() {
    final a = _assignment!;
    final orderNumber = a.order?.orderNumber ?? '--';
    final garmentCount = a.order?.garmentCount ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order summary card
          PressoCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PressoTokens.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: PressoTokens.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$orderNumber',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PressoTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$garmentCount items · In transit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PressoTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary panel: either the "start drop" CTA or the OTP + countdown
          if (_otp == null) _startPanel() else _otpPanel(),

          const SizedBox(height: 16),

          BtnOutline(
            label: 'Navigate to Facility',
            icon: Icons.navigation_outlined,
            onPressed: _navigate,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PressoTokens.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _startPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PressoTokens.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pin_outlined,
            size: 44,
            color: PressoTokens.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ready to hand over?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PressoTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When you reach the facility, tap below to generate a 4-digit code. '
            'Show it to the staff — they enter it on their app to confirm '
            'they received the bag.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: PressoTokens.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          BtnPrimary(
            label: _starting ? 'Generating code…' : 'Start Drop',
            icon: Icons.qr_code_2,
            onPressed: _starting ? null : _startDrop,
          ),
        ],
      ),
    );
  }

  Widget _otpPanel() {
    final otp = _otp!;
    final expired = _secondsRemaining == 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expired
              ? PressoTokens.red.withValues(alpha: .3)
              : PressoTokens.primary.withValues(alpha: .3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            expired ? 'Code expired' : 'Show this code to facility staff',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: expired
                  ? PressoTokens.red
                  : PressoTokens.textSecondary,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 14),
          // 4 big digit boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < otp.otp.length; i++) ...[
                _digitBox(otp.otp[i], expired: expired),
                if (i < otp.otp.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                size: 16,
                color: expired ? PressoTokens.red : PressoTokens.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                expired
                    ? 'Generate a new code to continue'
                    : 'Expires in ${_formatMmSs(_secondsRemaining)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: expired
                      ? PressoTokens.red
                      : PressoTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expired)
            BtnPrimary(
              label: _starting ? 'Generating…' : 'Generate new code',
              icon: Icons.refresh,
              onPressed: _starting ? null : _startDrop,
            )
          else
            const Text(
              'Waiting for facility to verify…',
              style: TextStyle(
                fontSize: 11,
                color: PressoTokens.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _digitBox(String digit, {required bool expired}) {
    return Container(
      width: 54,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: expired
            ? PressoTokens.red.withValues(alpha: .05)
            : PressoTokens.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expired
              ? PressoTokens.red.withValues(alpha: .3)
              : PressoTokens.primary.withValues(alpha: .3),
        ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: expired ? PressoTokens.red : PressoTokens.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
