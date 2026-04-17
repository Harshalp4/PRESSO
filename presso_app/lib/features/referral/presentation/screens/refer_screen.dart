import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../providers/referral_provider.dart';
import '../../domain/models/referral_model.dart';

class ReferScreen extends ConsumerStatefulWidget {
  const ReferScreen({super.key});

  @override
  ConsumerState<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends ConsumerState<ReferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(referralProvider.notifier).load();
    });
  }

  void _shareCode(String code, int bonusCoins, double coinRate) {
    final rupeeValue = (bonusCoins * coinRate).toStringAsFixed(0);
    final text =
        'Hey! Try Presso for laundry pickup & delivery. Use my code $code to get \u20B9$rupeeValue off your first order! \u{1F455}\u2728\nhttps://presso.app';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);
    final config = ref.watch(appConfigProvider);
    final bonusCoins = config.referralBonusCoins;
    final coinRate = config.coinValueRupees;
    final code = state.stats?.code ?? '';
    final rupeeValue = (bonusCoins * coinRate).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar: ← Refer & Earn ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '\u2190',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Refer & Earn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () =>
                          ref.read(referralProvider.notifier).refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Hero: gift + Give/Get + description ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 28, horizontal: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text('\u{1F381}',
                                        style: TextStyle(fontSize: 40)),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Give \u20B9$rupeeValue, Get \u20B9$rupeeValue',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Share your code. Both you and your friend\nget $bonusCoins coins (\u20B9$rupeeValue value) on their first order.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Referral code card (dashed teal border) ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: GestureDetector(
                                onTap: () {
                                  if (code.isNotEmpty) {
                                    Clipboard.setData(
                                        ClipboardData(text: code));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Referral code copied!'),
                                        behavior:
                                            SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                    dashWidth: 6,
                                    dashGap: 4,
                                    borderRadius: 14,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      color: AppColors.primary
                                          .withOpacity(0.04),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'YOUR REFERRAL CODE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          code.isNotEmpty
                                              ? code
                                              : '\u2022\u2022\u2022\u2022\u2022\u2022',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Share Code button ──
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: GestureDetector(
                                onTap: code.isNotEmpty
                                    ? () => _shareCode(
                                        code, bonusCoins, coinRate)
                                    : null,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0891B2),
                                        Color(0xFF0E7490)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0891B2)
                                            .withOpacity(0.25),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Share Code \u{1F517}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── YOUR REFERRALS section ──
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'YOUR REFERRALS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Referral list card ──
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border, width: 0.8),
                              ),
                              child: state.history.isEmpty
                                  ? _EmptyReferrals()
                                  : Column(
                                      children: [
                                        for (int i = 0;
                                            i < state.history.length;
                                            i++) ...[
                                          _ReferralRow(
                                              entry: state.history[i]),
                                          if (i <
                                              state.history.length - 1)
                                            const Divider(
                                              height: 1,
                                              thickness: 0.5,
                                              color: AppColors.divider,
                                              indent: 14,
                                              endIndent: 14,
                                            ),
                                        ],
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty referrals placeholder ─────────────────────────────────────────────

class _EmptyReferrals extends StatelessWidget {
  const _EmptyReferrals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Center(
        child: Column(
          children: const [
            Text('\u{1F465}', style: TextStyle(fontSize: 28)),
            SizedBox(height: 8),
            Text(
              'No referrals yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Share your code to start earning coins',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Referral row matching mockup ────────────────────────────────────────────

class _ReferralRow extends StatelessWidget {
  final ReferralHistory entry;

  const _ReferralRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final initial = entry.referredUserName.isNotEmpty
        ? entry.referredUserName[0].toUpperCase()
        : '?';

    final isCompleted = entry.isPaid;
    final statusLabel = isCompleted ? '\u2713 Completed' : 'Pending';
    final statusColor =
        isCompleted ? const Color(0xFF059669) : const Color(0xFFD97706);
    final avatarBg = isCompleted
        ? const Color(0xFF059669).withOpacity(0.1)
        : const Color(0xFFD97706).withOpacity(0.1);

    String subtitle;
    if (isCompleted) {
      subtitle = 'Joined ${_formatDate(entry.createdAt)}';
    } else {
      subtitle = 'Pending first order';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBg,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.referredUserName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    try {
      return DateFormat('d MMM').format(date);
    } catch (_) {
      return '';
    }
  }
}

// ─── Dashed border painter ───────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDash = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, nextDash), paint);
        distance = nextDash + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}
