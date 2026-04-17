import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/home_provider.dart';

class SavingsStrip extends ConsumerWidget {
  const SavingsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(userSavingsProvider);

    return savingsAsync.when(
      loading: () => _SavingsStripShimmer(),
      error: (_, __) => _SavingsContent(savings: 2340.0, orderCount: 68, context: context),
      data: (state) => _SavingsContent(
        savings: state.totalSavings,
        orderCount: state.orderCount,
        context: context,
      ),
    );
  }
}

class _SavingsContent extends StatelessWidget {
  final double savings;
  final int orderCount;
  final BuildContext context;

  const _SavingsContent({
    required this.savings,
    required this.orderCount,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final formattedSavings = _formatAmount(savings);

    return GestureDetector(
      onTap: () => context.push('/home/savings'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.green.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Text(
              '💰',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'You\'ve saved ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text: '₹$formattedSavings',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: ' with Presso · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text: '$orderCount orders',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_outlined,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final intAmount = amount.toInt();
      final thousands = intAmount ~/ 1000;
      final remainder = intAmount % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return amount.toStringAsFixed(0);
  }
}

class _SavingsStripShimmer extends StatefulWidget {
  @override
  State<_SavingsStripShimmer> createState() => _SavingsStripShimmerState();
}

class _SavingsStripShimmerState extends State<_SavingsStripShimmer>
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
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: const [
                AppColors.surfaceLight,
                Color(0xFF2A3A4A),
                AppColors.surfaceLight,
              ],
            ),
          ),
        );
      },
    );
  }
}
