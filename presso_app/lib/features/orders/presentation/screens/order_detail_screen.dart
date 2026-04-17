import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/domain/models/order_detail_model.dart';
import 'package:presso_app/features/orders/domain/models/order_item_model.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: orderAsync.when(
        loading: () => _buildAppBar(context, null),
        error: (_, __) => _buildAppBar(context, null),
        data: (order) => _buildAppBar(context, order),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load order details',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.refresh(orderDetailProvider(orderId)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetailContent(order: order),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, OrderDetailModel? order) {
    Color statusColor = AppColors.primary;
    String statusLabel = 'Loading';

    if (order != null) {
      statusLabel = order.statusLabel;
      switch (order.effectiveStatus) {
        case 'delivered':
          statusColor = AppColors.green;
          break;
        case 'cancelled':
          statusColor = AppColors.red;
          break;
        case 'picked_up':
        case 'pickedup':
        case 'at_facility':
        case 'atfacility':
        case 'washing':
        case 'ironing':
        case 'processing':
        case 'inprocess':
        case 'in_process':
        case 'ready':
        case 'readyfordelivery':
        case 'ready_for_delivery':
        case 'out_for_delivery':
        case 'outfordelivery':
          statusColor = AppColors.primary;
          break;
        default:
          statusColor = AppColors.amber;
      }
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text('Order Detail', style: AppTextStyles.heading3),
      titleSpacing: 0,
      actions: [
        if (order != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderDetailModel order;

  const _OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status strip
                if (order.effectiveStatus == 'delivered' &&
                    order.deliveredAt != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: AppColors.green.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Delivered on ${DateFormat('d MMM').format(order.deliveredAt!)} at ${DateFormat('h:mm a').format(order.deliveredAt!)}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ITEMS section — grouped by service
                      _SectionHeader(title: 'ITEMS'),
                      const SizedBox(height: 8),
                      ..._buildGroupedItems(order),
                      const SizedBox(height: 16),

                      // Price breakdown
                      _SectionHeader(title: 'PRICE BREAKDOWN'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            _PriceRow(
                                label: 'Subtotal',
                                amount: order.subTotal),
                            if (order.studentDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _PriceRow(
                                label: 'Student discount',
                                amount: -order.studentDiscount,
                                valueColor: AppColors.green,
                              ),
                            ],
                            if (order.coinDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _PriceRow(
                                label:
                                    'Coins (${order.coinsRedeemed} coins)',
                                amount: -order.coinDiscount,
                                valueColor: AppColors.green,
                              ),
                            ],
                            if (order.expressCharge > 0) ...[
                              const SizedBox(height: 8),
                              _PriceRow(
                                label: 'Express delivery',
                                amount: order.expressCharge,
                              ),
                            ],
                            if (order.adminDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _PriceRow(
                                label: 'Admin discount',
                                amount: -order.adminDiscount,
                                valueColor: AppColors.green,
                              ),
                            ],
                            const SizedBox(height: 10),
                            const Divider(
                                color: AppColors.divider, height: 1),
                            const SizedBox(height: 10),
                            _PriceRow(
                              label: 'Total paid',
                              amount: order.totalAmount,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pickup photos
                      if (order.pickupPhotoUrls.isNotEmpty) ...[
                        _SectionHeader(
                          title:
                              'PICKUP PHOTOS (${order.totalItemCount} ITEMS)',
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.border, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...order.pickupPhotoUrls
                                      .take(4)
                                      .map((url) => Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: NetworkImage(url),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )),
                                  if (order.pickupPhotoUrls.length > 4)
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+${order.pickupPhotoUrls.length - 4}',
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => context.push(
                                    '/order/${order.id}/photos',
                                    extra: order.pickupPhotoUrls),
                                child: Text(
                                  'View all →',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Timeline
                      _SectionHeader(title: 'TIMELINE'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: _OrderTimeline(order: order),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border:
                Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: PressoButton(
                      label: 'Reorder',
                      type: PressoButtonType.outline,
                      icon: Icons.replay_rounded,
                      onPressed: () {
                        context.push('/order/services');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PressoButton(
                      label: 'Rate Order',
                      icon: Icons.star_rounded,
                      onPressed: () {
                        _showRatingDialog(context, order.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupedItems(OrderDetailModel order) {
    // Group items by serviceName
    final Map<String, List<OrderItemModel>> grouped = {};
    for (final item in order.items) {
      final key = item.serviceName.isNotEmpty ? item.serviceName : 'Items';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final serviceName = entry.key;
      final items = entry.value;
      final serviceTotal =
          items.fold<double>(0, (sum, i) => sum + i.subtotal);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      serviceName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '₹${serviceTotal.toStringAsFixed(0)}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Item rows
            ...items.map((item) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.garmentTypeName,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '× ${item.quantity}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '₹${item.subtotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      );
    }).toList();
  }

  void _showRatingDialog(BuildContext context, String orderId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RatingSheet(orderId: orderId),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final OrderDetailModel order;

  const _OrderTimeline({required this.order});

  // Returns the visible events in reverse-chronological order (latest first).
  // We surface every stage the backend has a timestamp for so the customer
  // sees the exact same story the facility and rider apps show — processing
  // label reflects the actual facility sub-stage in flight (washing / ironing
  // / ready) when available.
  List<_TimelineEvent> get _events {
    final events = <_TimelineEvent>[];

    if (order.deliveredAt != null) {
      events.add(_TimelineEvent(
        label: 'Delivered',
        date: order.deliveredAt!,
        color: AppColors.green,
      ));
    }

    if (order.outForDeliveryAt != null) {
      events.add(_TimelineEvent(
        label: 'Out for delivery',
        date: order.outForDeliveryAt!,
        color: AppColors.primary,
      ));
    }

    if (order.readyAt != null) {
      events.add(_TimelineEvent(
        label: 'Ready for delivery',
        date: order.readyAt!,
        color: AppColors.primary,
      ));
    }

    if (order.processingStartedAt != null) {
      final stage = order.facilityStage?.toLowerCase();
      final label = (stage == 'ironing')
          ? 'Ironing started'
          : (stage == 'washing')
              ? 'Washing started'
              : 'Processing started';
      events.add(_TimelineEvent(
        label: label,
        date: order.processingStartedAt!,
        color: AppColors.primary,
      ));
    }

    if (order.facilityReceivedAt != null) {
      events.add(_TimelineEvent(
        label: 'Received at facility',
        date: order.facilityReceivedAt!,
        color: AppColors.primary,
      ));
    }

    if (order.pickedUpAt != null) {
      events.add(_TimelineEvent(
        label: 'Picked up',
        date: order.pickedUpAt!,
        color: AppColors.green,
      ));
    }

    events.add(_TimelineEvent(
      label: 'Order placed',
      date: order.createdAt,
      color: AppColors.primary,
    ));

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return Column(
      children: List.generate(events.length, (i) {
        final event = events[i];
        final isLast = i == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 36,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      DateFormat('d MMM, h:mm a').format(event.date),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineEvent {
  final String label;
  final DateTime date;
  final Color color;

  const _TimelineEvent({
    required this.label,
    required this.date,
    required this.color,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? valueColor;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.body.copyWith(color: AppColors.textSecondary);

    final isNeg = amount < 0;
    final display = '${isNeg ? '-₹' : '₹'}${amount.abs().toStringAsFixed(0)}';

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          display,
          style: style.copyWith(
            color: valueColor ??
                (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _RatingSheet extends StatefulWidget {
  final String orderId;
  const _RatingSheet({required this.orderId});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rate your order',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 36,
                    color: AppColors.amber,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          PressoButton(
            label: 'Submit Rating',
            onPressed: _rating > 0
                ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
