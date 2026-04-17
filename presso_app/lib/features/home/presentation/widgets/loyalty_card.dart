import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/home_provider.dart';

class LoyaltyCard extends ConsumerWidget {
  const LoyaltyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinAsync = ref.watch(coinBalanceProvider);

    return coinAsync.when(
      loading: () => _LoyaltyShimmer(),
      error: (_, __) => _LoyaltyContent(
        balance: 1240,
        tier: 'Gold',
        coinsToNextTier: 260,
        nextTierName: 'Platinum',
        progressValue: 0.83,
        rupeesEquivalent: '₹124',
        context: context,
      ),
      data: (state) => _LoyaltyContent(
        balance: state.balance,
        tier: state.tier,
        coinsToNextTier: state.coinsToNextTier,
        nextTierName: state.nextTierName,
        progressValue: state.progressToNextTier(),
        rupeesEquivalent: state.rupeesEquivalent,
        context: context,
      ),
    );
  }
}

class _LoyaltyContent extends StatelessWidget {
  final int balance;
  final String tier;
  final int coinsToNextTier;
  final String nextTierName;
  final double progressValue;
  final String rupeesEquivalent;
  final BuildContext context;

  const _LoyaltyContent({
    required this.balance,
    required this.tier,
    required this.coinsToNextTier,
    required this.nextTierName,
    required this.progressValue,
    required this.rupeesEquivalent,
    required this.context,
  });

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'gold':
        return AppColors.amber;
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _formattedBalance {
    if (balance >= 1000) {
      final t = balance ~/ 1000;
      final r = balance % 1000;
      return '$t,${r.toString().padLeft(3, '0')}';
    }
    return balance.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/savings'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 16,
                  color: AppColors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  'Presso Coins',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Tier badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tierColor.withOpacity(0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${tier.toUpperCase()} TIER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _tierColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Coin number + value
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formattedBalance,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '= $rupeesEquivalent',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tier,
                      style: AppTextStyles.caption.copyWith(
                        color: _tierColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      coinsToNextTier > 0
                          ? '$coinsToNextTier coins to $nextTierName'
                          : 'Max tier reached!',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                    if (coinsToNextTier > 0)
                      Text(
                        nextTierName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
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

class _LoyaltyShimmer extends StatefulWidget {
  @override
  State<_LoyaltyShimmer> createState() => _LoyaltyShimmerState();
}

class _LoyaltyShimmerState extends State<_LoyaltyShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: const [
                AppColors.surface,
                AppColors.surfaceLight,
                AppColors.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}
