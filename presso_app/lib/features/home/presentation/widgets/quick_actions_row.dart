import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  static const List<_QuickAction> _actions = [
    _QuickAction(
      label: 'Book\nPickup',
      icon: Icons.add_shopping_cart_rounded,
      color: AppColors.primary,
      route: '/order/services',
    ),
    _QuickAction(
      label: 'My\nCart',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.amber,
      route: '/order/garments', // placeholder, handled specially
    ),
    _QuickAction(
      label: 'My\nOrders',
      icon: Icons.receipt_long_outlined,
      color: AppColors.purple,
      route: '/home/orders',
    ),
    _QuickAction(
      label: 'Wallet\n& Coins',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.green,
      route: '/home/savings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(createOrderFlowProvider).totalItemCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: AppTextStyles.heading3.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _actions.map((action) {
              final isCart = action.label == 'My\nCart';
              return _QuickActionButton(
                action: action,
                badge: isCart && cartCount > 0 ? cartCount : null,
                onTap: () {
                  if (isCart) {
                    // If cart has items or services selected, go to garments
                    final flow = ref.read(createOrderFlowProvider);
                    if (flow.selectedServices.isNotEmpty) {
                      context.push('/order/garments');
                    } else {
                      // Empty cart → start from service selection
                      context.push('/order/services');
                    }
                  } else {
                    context.push(action.route);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  final int? badge;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.action,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: action.color.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    action.icon,
                    size: 24,
                    color: action.color,
                  ),
                ),
                // Badge for cart count
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badge.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
