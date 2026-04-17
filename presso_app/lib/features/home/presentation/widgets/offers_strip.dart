import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/app_config_provider.dart';

class OffersStrip extends StatelessWidget {
  const OffersStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Offers for you',
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/order/services'),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Flash deal card
        _FlashDealCard(),

        const SizedBox(height: 10),

        // Student offer card
        _StudentOfferCard(),
      ],
    );
  }
}

class _FlashDealCard extends StatefulWidget {
  @override
  State<_FlashDealCard> createState() => _FlashDealCardState();
}

class _FlashDealCardState extends State<_FlashDealCard> {
  late Duration _remaining;
  Timer? _timer;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    // Countdown target: end of today at 23:59 or a fixed 2h 14m
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, now.hour + 2, now.minute + 14);
    _remaining = end.difference(now);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/order/services'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.amber.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Left: badge + content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '⚡ FLASH DEAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '30% off dry clean',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in $_countdownText',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Code chip
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'FLASH30'));
                      setState(() => _copied = true);
                      Future.delayed(
                          const Duration(seconds: 2),
                          () => mounted ? setState(() => _copied = false) : null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.amber.withOpacity(0.4),
                          width: 0.8,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FLASH30',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _copied
                                  ? AppColors.green
                                  : AppColors.amber,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            _copied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 12,
                            color: _copied
                                ? AppColors.green
                                : AppColors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right: big discount number
            const SizedBox(width: 12),
            Column(
              children: [
                const Text(
                  '30%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amber,
                    height: 1,
                  ),
                ),
                const Text(
                  'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentOfferCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountPct = ref.watch(appConfigProvider).studentDiscountPercent;
    return GestureDetector(
      onTap: () => context.push('/profile/student-verify'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.green.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '🎓 STUDENT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$discountPct% off every order',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Verify college ID once',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.green.withOpacity(0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Verify now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
