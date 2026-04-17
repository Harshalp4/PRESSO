import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';

class OrderConfirmedScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmedScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderConfirmedScreen> createState() =>
      _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState extends ConsumerState<OrderConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: orderAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => _buildContent(context, null),
            data: (order) => _buildContent(context, order),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic order) {
    final orderNumber = order?.orderNumber ?? 'PRE-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final totalItems = order?.totalItemCount ?? 0;
    final totalAmount = order?.totalAmount ?? 0.0;
    final coinsEarned = order?.coinsEarned ?? 0;
    final slot = order?.pickupSlot;
    final slotDisplay = slot != null
        ? '${slot.date} · ${slot.displayTime}'
        : 'Scheduled';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Animated green check
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Order placed
          Text(
            'Order Placed!',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.green,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll arrive for pickup on",
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            slotDisplay,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Order ID', value: orderNumber, valueColor: AppColors.primary),
                const Divider(color: AppColors.divider, height: 20),
                _InfoRow(
                  label: 'Items',
                  value: '$totalItems ${totalItems == 1 ? 'piece' : 'pieces'}',
                ),
                const Divider(color: AppColors.divider, height: 20),
                _InfoRow(
                  label: 'Amount paid',
                  value: '₹${totalAmount.toStringAsFixed(0)}',
                ),
                const Divider(color: AppColors.divider, height: 20),
                _InfoRow(
                  label: 'Est. delivery',
                  value: 'Tomorrow by 9 PM',
                  valueColor: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coins earned strip
          if (coinsEarned > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.purpleLight.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded,
                      color: AppColors.purpleLight, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'You earned $coinsEarned Presso Coins!',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.purpleLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Buttons
          PressoButton(
            label: 'Track Order',
            icon: Icons.location_on_rounded,
            onPressed: () =>
                context.push('/order/${widget.orderId}/track'),
          ),
          const SizedBox(height: 12),
          PressoButton(
            label: 'Back to Home',
            type: PressoButtonType.outline,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
