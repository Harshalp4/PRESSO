// Job Locked screen — wireframe screen 6.
//
// Shown when a rider's accept attempt loses the race. The reason string is
// passed via GoRouter `extra` and tells us *why*:
//   - "expired"          → the 60-second window elapsed
//   - "offer_expired"    → server detected expiry on accept
//   - "offer_lost"       → another rider's accept won the xmin race
//   - "offer_not_available" / anything else → generic
//
// The CTA returns the rider to the dashboard so they can pick the next job.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/rider/presentation/providers/rider_provider.dart';

class JobLockedScreen extends ConsumerWidget {
  final String reason;

  const JobLockedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, message, icon, color) = switch (reason) {
      'expired' || 'offer_expired' => (
        'Offer Expired',
        'You took too long to respond.\nThe job has been offered to another rider.',
        Icons.schedule,
        PressoTokens.amber,
      ),
      'offer_lost' => (
        'Job Locked',
        'Another rider accepted this job\nbefore you. Better luck next time!',
        Icons.lock_outline,
        PressoTokens.red,
      ),
      _ => (
        'Offer Unavailable',
        'This offer is no longer available.',
        Icons.block,
        PressoTokens.textSecondary,
      ),
    };

    return Scaffold(
      backgroundColor: PressoTokens.bg,
      body: SafeArea(
        child: PhoneColumn(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 56, color: color),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PressoTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: PressoTokens.textSecondary,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: BtnPrimary(
                    label: 'Back to Jobs',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      ref.read(currentOfferProvider.notifier).clear();
                      ref.read(riderProvider.notifier).loadJobs();
                      context.go('/rider/dashboard');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
