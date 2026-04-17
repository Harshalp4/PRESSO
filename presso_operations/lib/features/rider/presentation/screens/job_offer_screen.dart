// Job Offer screen — wireframe 2b · JOB OFFER · NEW.
//
// When the dispatcher hands a rider an Offered assignment, the app pushes
// this screen as a full-screen takeover with a 60-second countdown. The rider
// can Accept (which races against other riders via Postgres xmin) or Decline
// (which frees the order back to the queue).
//
// On a 409 from the accept endpoint we navigate to the JobLockedScreen so the
// rider sees why the offer is no longer theirs (expired vs lost the race).

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/rider_provider.dart';

class JobOfferScreen extends ConsumerStatefulWidget {
  final AssignmentModel offer;

  const JobOfferScreen({super.key, required this.offer});

  @override
  ConsumerState<JobOfferScreen> createState() => _JobOfferScreenState();
}

class _JobOfferScreenState extends ConsumerState<JobOfferScreen> {
  Timer? _ticker;
  late int _secondsLeft;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.offer.secondsRemaining ??
        (widget.offer.offerExpiresAt
                ?.difference(DateTime.now().toUtc())
                .inSeconds ??
            60);
    if (_secondsLeft < 0) _secondsLeft = 0;

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _goToLocked('expired');
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _goToLocked(String reason) {
    if (!mounted) return;
    context.pushReplacement('/rider/offer/locked', extra: reason);
  }

  Future<void> _accept() async {
    if (_busy) return;
    // Stop the ticker BEFORE the API call so a race at t=0 can't bounce the
    // rider to the "Offer Expired" screen after a successful accept.
    _ticker?.cancel();
    setState(() => _busy = true);
    try {
      await ref.read(riderRepositoryProvider).acceptAssignment(widget.offer.id);
      ref.read(currentOfferProvider.notifier).clear();
      ref.read(riderProvider.notifier).loadJobs();
      if (!mounted) return;
      // Route by assignment type: delivery offers take the rider to the
      // delivery screen, pickups to the pickup job screen. Mis-routing a
      // delivery into the pickup flow previously let riders confirm-pickup
      // on a delivery assignment, which rolled the order back from
      // OutForDelivery to PickedUp.
      final isDelivery = widget.offer.type == 'Delivery';
      final nextPath = isDelivery
          ? '/rider/delivery/${widget.offer.id}'
          : '/rider/job/${widget.offer.id}';
      context.pushReplacement(nextPath);
    } on DioException catch (e) {
      _ticker?.cancel();
      final code = (e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['code'] as String?
          : null;
      _goToLocked(code ?? 'unavailable');
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    if (_busy) return;
    _ticker?.cancel();
    setState(() => _busy = true);
    try {
      await ref.read(riderRepositoryProvider).declineAssignment(widget.offer.id);
      ref.read(currentOfferProvider.notifier).clear();
      ref.read(riderProvider.notifier).loadJobs();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtMMSS(int total) {
    if (total < 0) total = 0;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.offer.order;
    final addr = widget.offer.address;
    final urgent = _secondsLeft <= 10;

    // Progress 0.0 → 1.0 draining to the right, matches the wireframe bar.
    // Defaults to 60s if the offer never carried a secondsRemaining.
    final initialSeconds = widget.offer.secondsRemaining ??
        widget.offer.offerExpiresAt
            ?.difference(widget.offer.assignedAt ?? DateTime.now().toUtc())
            .inSeconds ??
        60;
    final progress =
        initialSeconds <= 0 ? 0.0 : (_secondsLeft / initialSeconds).clamp(0.0, 1.0);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: PressoTokens.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: const [
              Text(
                'New pickup offer',
                style: TextStyle(
                  color: PressoTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              SizedBox(width: 10),
              PressoChip(label: 'NEW', color: PressoChipColor.teal),
            ],
          ),
        ),
        body: SafeArea(
          child: PhoneColumn(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _warningBanner(),
                        const SizedBox(height: 14),
                        _respondTimerCard(progress, urgent),
                        const SizedBox(height: 14),
                        _jobCard(order, addr),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      // 1:2 ratio per wireframe — Accept gets the emphasis.
                      Expanded(
                        flex: 1,
                        child: BtnOutline(
                          label: 'Decline',
                          color: PressoTokens.red,
                          onPressed: _busy ? null : _decline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: BtnPrimary(
                          label: _busy ? 'Accepting...' : 'Accept',
                          icon: Icons.check_circle_outline,
                          onPressed: _busy ? null : _accept,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: Text(
                      'Auto-released to next rider at 0',
                      style: TextStyle(
                        fontSize: 11,
                        color: PressoTokens.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Red dashed warning note — "Solves 'two riders same order'"
  Widget _warningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PressoTokens.red.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PressoTokens.red.withValues(alpha: .35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: PressoTokens.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "⚠ Solves 'two riders same order'",
                  style: TextStyle(
                    color: PressoTokens.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Dispatcher pre-assigns one rider. Timer prevents stuck '
                  'jobs — auto-releases to next rider at 0.',
                  style: TextStyle(
                    color: PressoTokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Teal gradient "RESPOND IN 00:42" countdown card with progress bar.
  // Matches wireframe 2b — gradient from #0891b2 → #06b6d4, white text,
  // 4px progress bar underneath that drains to the right.
  Widget _respondTimerCard(double progress, bool urgent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: urgent
              ? const [Color(0xFFDC2626), Color(0xFFEF4444)]
              : const [Color(0xFF0891B2), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'RESPOND IN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtMMSS(_secondsLeft),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar — drains right→left as the timer counts down.
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Pickup job card — matches the dashboard job card style.
  Widget _jobCard(AssignmentOrderModel? order, AddressModel? addr) {
    final garmentCount = order?.garmentCount ?? 0;
    final city = addr?.city ?? addr?.fullAddress ?? '';
    final customerName = widget.offer.customer?.name ?? 'Customer';
    final slot = order?.pickupSlotDisplay;
    final express = order?.isExpressDelivery == true;
    final payout = widget.offer.payoutAmount;

    final subtitleParts = <String>[
      if (customerName.isNotEmpty) customerName,
      if (city.isNotEmpty) city,
    ];
    final secondLineParts = <String>[
      if (slot != null && slot.isNotEmpty) 'Slot $slot',
    ];

    return PressoCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: "#PR-xxxx · Pickup"                        ₹80
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '#${order?.orderNumber ?? '—'} · Pickup',
                  style: const TextStyle(
                    color: PressoTokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (payout != null)
                Text(
                  '\u20B9${payout.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: PressoTokens.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: "Customer · City"
          Text(
            subtitleParts.join(' · '),
            style: const TextStyle(
              color: PressoTokens.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (secondLineParts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              secondLineParts.join(' · '),
              style: const TextStyle(
                color: PressoTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Row 3: 📦 N garments    [Express chip]
          Row(
            children: [
              const Text('📦 ', style: TextStyle(fontSize: 13)),
              Text(
                '$garmentCount garments',
                style: const TextStyle(
                  color: PressoTokens.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (express)
                const PressoChip(
                  label: 'Express',
                  color: PressoChipColor.amber,
                  icon: Icons.bolt,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
