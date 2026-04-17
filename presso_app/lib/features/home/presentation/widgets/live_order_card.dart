import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/home_provider.dart';
import 'photo_proof_strip.dart';

class LiveOrderCard extends ConsumerWidget {
  const LiveOrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(activeOrderProvider);

    return orderAsync.when(
      loading: () => _LiveOrderShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (order) {
        if (order == null) return const SizedBox.shrink();
        return _LiveOrderContent(order: order);
      },
    );
  }
}

class _LiveOrderContent extends StatelessWidget {
  final dynamic order; // ActiveOrderSummary

  const _LiveOrderContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _OrderStep(label: 'Picked', icon: Icons.inventory_2_outlined),
      _OrderStep(label: 'Facility', icon: Icons.warehouse_outlined),
      _OrderStep(label: 'Processing', icon: Icons.local_laundry_service_outlined),
      _OrderStep(label: 'Delivery', icon: Icons.local_shipping_outlined),
    ];

    return Container(
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
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${order.orderNumber} · Live',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/order/${order.orderId}/track'),
                child: Row(
                  children: [
                    Text(
                      'Full tracker',
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

          const SizedBox(height: 6),

          // Subtitle
          Text(
            order.agentName != null
                ? 'Pickup photos · ${order.agentName} collected these'
                : 'Pickup photos',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          // Photo strip
          PhotoProofStrip(
            photoUrls: order.photoUrls,
            maxVisible: 4,
            onViewAll: () => context.push('/order/${order.orderId}/photos'),
          ),

          const SizedBox(height: 16),

          // 4-step progress tracker
          _ProgressTracker(
            steps: steps,
            currentStep: order.currentStep,
          ),
        ],
      ),
    );
  }
}

class _OrderStep {
  final String label;
  final IconData icon;
  const _OrderStep({required this.label, required this.icon});
}

class _ProgressTracker extends StatelessWidget {
  final List<_OrderStep> steps;
  final int currentStep;

  const _ProgressTracker({
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone
                  ? AppColors.green
                  : AppColors.border,
            ),
          );
        }

        // Step circle
        final stepIndex = index ~/ 2;
        final isDone = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        Color circleColor;
        Color iconColor;
        Widget? iconWidget;

        if (isDone) {
          circleColor = AppColors.green;
          iconColor = Colors.white;
          iconWidget = const Icon(Icons.check, size: 12, color: Colors.white);
        } else if (isCurrent) {
          circleColor = AppColors.primary.withOpacity(0.15);
          iconColor = AppColors.primary;
          iconWidget = Icon(
            steps[stepIndex].icon,
            size: 12,
            color: AppColors.primary,
          );
        } else {
          circleColor = AppColors.surfaceLight;
          iconColor = AppColors.textHint;
          iconWidget = Icon(
            steps[stepIndex].icon,
            size: 12,
            color: AppColors.textHint,
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex].label,
              style: TextStyle(
                fontSize: 9,
                color: isDone
                    ? AppColors.green
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.textHint,
                fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LiveOrderShimmer extends StatefulWidget {
  @override
  State<_LiveOrderShimmer> createState() => _LiveOrderShimmerState();
}

class _LiveOrderShimmerState extends State<_LiveOrderShimmer>
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
          height: 180,
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
