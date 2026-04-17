import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);
    final notifier = ref.read(createOrderFlowProvider.notifier);
    final totalItems = flowState.totalItemCount;
    final subtotal = flowState.subtotal;
    final isEmpty = flowState.selectedServices.isEmpty && totalItems == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('My Cart', style: AppTextStyles.heading3),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () {
                _confirmClear(context, notifier);
              },
              child: Text(
                'Clear',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: isEmpty ? _EmptyCart() : _CartContent(flowState: flowState, notifier: notifier),
      bottomNavigationBar: isEmpty
          ? null
          : _CartBottomBar(
              totalItems: totalItems,
              subtotal: subtotal,
              hasMinItems: totalItems >= 3,
              hasServices: flowState.selectedServices.isNotEmpty,
            ),
    );
  }

  void _confirmClear(BuildContext context, CreateOrderFlowNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Cart', style: AppTextStyles.heading3),
        content: Text(
          'Remove all items and start fresh?',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: AppTextStyles.button.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your cart is empty',
              style: AppTextStyles.heading3.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from our services to get started with your laundry order.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PressoButton(
              label: 'Browse Services',
              icon: Icons.add_shopping_cart_rounded,
              width: 200,
              onPressed: () => context.push('/order/services'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart content ────────────────────────────────────────────────────────────

class _CartContent extends StatelessWidget {
  final CreateOrderFlowState flowState;
  final CreateOrderFlowNotifier notifier;

  const _CartContent({required this.flowState, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Services with items
        ...flowState.selectedServices.map((service) {
          final items = _getServiceItems(service);
          if (items.isEmpty) {
            return _EmptyServiceCard(service: service);
          }
          return _ServiceCard(
            service: service,
            items: items,
            notifier: notifier,
          );
        }),

        const SizedBox(height: 12),

        // Add more items button
        GestureDetector(
          onTap: () => context.push('/order/garments'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Edit items',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Add more services
        GestureDetector(
          onTap: () => context.push('/order/services'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Add more services',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_CartItem> _getServiceItems(ServiceModel service) {
    final items = <_CartItem>[];
    for (final garment in service.garmentTypes) {
      final key = '${service.id}_${garment.id}';
      final count = flowState.garmentCounts[key] ?? 0;
      if (count > 0) {
        final price = garment.priceOverride ?? service.pricePerPiece;
        items.add(_CartItem(
          name: garment.name,
          count: count,
          price: price,
          serviceId: service.id,
          garmentTypeId: garment.id,
        ));
      }
    }
    return items;
  }
}

class _CartItem {
  final String name;
  final int count;
  final double price;
  final String serviceId;
  final String garmentTypeId;

  const _CartItem({
    required this.name,
    required this.count,
    required this.price,
    required this.serviceId,
    required this.garmentTypeId,
  });
}

// ─── Service card with items ─────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final List<_CartItem> items;
  final CreateOrderFlowNotifier notifier;

  const _ServiceCard({
    required this.service,
    required this.items,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final serviceTotal =
        items.fold(0.0, (sum, item) => sum + item.price * item.count);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Service header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${serviceTotal.toStringAsFixed(0)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${item.count} × ₹${item.price.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${(item.count * item.price).toStringAsFixed(0)}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Empty service (selected but no items added) ─────────────────────────────

class _EmptyServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _EmptyServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            service.name,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            'No items added',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ──────────────────────────────────────────────────────────────

class _CartBottomBar extends StatelessWidget {
  final int totalItems;
  final double subtotal;
  final bool hasMinItems;
  final bool hasServices;

  const _CartBottomBar({
    required this.totalItems,
    required this.subtotal,
    required this.hasMinItems,
    required this.hasServices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalItems pcs · ₹${subtotal.toStringAsFixed(0)}',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      hasMinItems
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 12,
                      color: hasMinItems
                          ? AppColors.green
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasMinItems
                          ? 'Min 3 items done'
                          : 'Min 3 items required',
                      style: AppTextStyles.caption.copyWith(
                        color: hasMinItems
                            ? AppColors.green
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PressoButton(
            label: 'Pick Slot',
            trailingIcon: Icons.arrow_forward_rounded,
            width: 130,
            height: 44,
            onPressed: hasMinItems
                ? () => context.push('/order/slots')
                : null,
          ),
        ],
      ),
    );
  }
}
