import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/shimmer_loader.dart';
import 'package:presso_app/features/orders/domain/models/order_model.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';

const _filterTabs = ['All', 'Active', 'Completed', 'Cancelled'];

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() =>
      _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _selectedFilter = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(ordersListProvider.notifier).loadOrders();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ordersListProvider.notifier).loadMore();
    }
  }

  void _applyFilter(String filter) {
    setState(() => _selectedFilter = filter);
    ref
        .read(ordersListProvider.notifier)
        .loadOrders(statusFilter: filter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Orders', style: AppTextStyles.heading3),
        titleSpacing: 16,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Show filter bottom sheet
            },
            icon: const Icon(Icons.tune_rounded,
                size: 16, color: AppColors.primary),
            label: const Text(
              'Filter',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => _applyFilter(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.background
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: state.isLoading
                ? const _OrdersShimmer()
                : state.error != null
                    ? _ErrorState(
                        errorType: state.error!,
                        onRetry: () => ref
                            .read(ordersListProvider.notifier)
                            .loadOrders(),
                      )
                    : state.orders.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            onRefresh: () => ref
                                .read(ordersListProvider.notifier)
                                .refresh(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: state.orders.length +
                                  (state.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.orders.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.primary),
                                      ),
                                    ),
                                  );
                                }
                                final order = state.orders[index];
                                return _OrderCard(
                                  order: order,
                                  onTap: () =>
                                      context.push('/order/${order.id}/detail'),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  // Distinct color per lifecycle stage. Previously every in-flight order got
  // the same teal chip so the user couldn't tell them apart — this maps the
  // effective status (InProcess expanded via facilityStage) to a colour the
  // chip, progress dots and timeline line all share.
  Color _statusColor(String effective) {
    switch (effective) {
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      case 'pending':
      case 'confirmed':
      case 'riderassigned':
      case 'rider_assigned':
      case 'pickupinprogress':
        return AppColors.amber;
      case 'picked_up':
      case 'pickedup':
        return const Color(0xFF6C5CE7); // indigo — order is in transit
      case 'at_facility':
      case 'atfacility':
        return const Color(0xFF00B894); // teal green — arrived at facility
      case 'washing':
      case 'ironing':
      case 'processing':
      case 'inprocess':
      case 'in_process':
        return AppColors.primary; // brand blue — being serviced
      case 'ready':
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return const Color(0xFFFD9644); // orange — waiting for delivery rider
      case 'out_for_delivery':
      case 'outfordelivery':
        return const Color(0xFF0984E3); // bright blue — on the way
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String effective) {
    // Mirrors OrderDetailModel.statusLabel so the history card matches the
    // detail/tracker screens when the facility is mid-processing.
    switch (effective) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'riderassigned':
      case 'rider_assigned':
        return 'Rider Assigned';
      case 'pickupinprogress':
        return 'Pickup in Progress';
      case 'picked_up':
      case 'pickedup':
        return 'Picked Up';
      case 'at_facility':
      case 'atfacility':
        return 'At Facility';
      case 'washing':
        return 'Washing';
      case 'ironing':
        return 'Ironing';
      case 'processing':
      case 'inprocess':
      case 'in_process':
        return 'Processing';
      case 'ready':
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return 'Ready for Delivery';
      case 'out_for_delivery':
      case 'outfordelivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return effective;
    }
  }

  // Maps the effective status to the 5-step mini tracker:
  //   0 Picked · 1 Facility · 2 Processing · 3 Out for delivery · 4 Delivered
  // Returns -1 for pre-pickup (pending/confirmed/rider assigned) so the bar
  // shows as fully empty.
  int _trackerStep(String effective) {
    switch (effective) {
      case 'picked_up':
      case 'pickedup':
        return 0;
      case 'at_facility':
      case 'atfacility':
        return 1;
      case 'washing':
      case 'ironing':
      case 'processing':
      case 'inprocess':
      case 'in_process':
      case 'ready':
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return 2;
      case 'out_for_delivery':
      case 'outfordelivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return -1;
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('d MMM, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final effective = order.effectiveStatus;
    final statusColor = _statusColor(effective);
    final statusLabel = _statusLabel(effective);
    final step = _trackerStep(effective);
    final isCancelled = effective == 'cancelled';
    final showTracker = !isCancelled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          // Subtle coloured left rail so the stage is readable at a glance
          // without relying on the chip alone.
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — order number + amount + status chip
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.createdAt),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Meta row — items / slot / express
            if (order.itemCount > 0 ||
                order.serviceSummary.isNotEmpty ||
                order.pickupSlotDisplay.isNotEmpty ||
                order.isExpressDelivery)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (order.itemCount > 0 || order.serviceSummary.isNotEmpty)
                      Text(
                        order.itemCount > 0 && order.serviceSummary.isNotEmpty
                            ? '${order.itemCount} items · ${order.serviceSummary}'
                            : order.serviceSummary.isNotEmpty
                                ? order.serviceSummary
                                : '${order.itemCount} items',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (order.pickupSlotDisplay.isNotEmpty)
                      Text(
                        '· ${order.pickupSlotDisplay}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    if (order.isExpressDelivery)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 12, color: AppColors.amber),
                          Text(
                            'Express',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

            // Mini tracker
            if (showTracker)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: _MiniTracker(
                  currentStep: step,
                  color: statusColor,
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// 5-step inline tracker: Picked → Facility → Processing → OFD → Delivered.
/// The connecting bar segment is filled when the step is reached, and the
/// active step pulses in the status colour so the user can see exactly
/// where the order currently is without opening the detail screen.
class _MiniTracker extends StatelessWidget {
  final int currentStep; // -1 = nothing reached yet
  final Color color;

  const _MiniTracker({required this.currentStep, required this.color});

  static const _labels = ['Picked', 'Facility', 'Processing', 'OFD', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dots + connecting bars
        Row(
          children: List.generate(_labels.length * 2 - 1, (i) {
            if (i.isEven) {
              final stepIdx = i ~/ 2;
              final reached = currentStep >= stepIdx;
              final isActive = currentStep == stepIdx;
              return _TrackerDot(
                reached: reached,
                isActive: isActive,
                color: color,
              );
            } else {
              final leftStep = (i - 1) ~/ 2;
              final reached = currentStep > leftStep;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: reached ? color : AppColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        // Labels
        Row(
          children: List.generate(_labels.length, (i) {
            final reached = currentStep >= i;
            final isActive = currentStep == i;
            return Expanded(
              child: Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  color: reached ? color : AppColors.textHint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TrackerDot extends StatelessWidget {
  final bool reached;
  final bool isActive;
  final Color color;

  const _TrackerDot({
    required this.reached,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      // Active step is a filled dot with a halo so the eye lands on it.
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    if (reached) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: AppColors.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: AppTextStyles.heading3
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Place your first order to see it here',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Place First Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatefulWidget {
  final String errorType; // 'connection' or 'server'
  final VoidCallback onRetry;

  const _ErrorState({required this.errorType, required this.onRetry});

  @override
  State<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<_ErrorState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
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
    final isConnection = widget.errorType == 'connection';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnim.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isConnection
                                ? AppColors.amber
                                : AppColors.red)
                            .withValues(alpha: 0.06),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isConnection
                                ? AppColors.amber
                                : AppColors.red)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    // Icon circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isConnection
                                ? AppColors.amber
                                : AppColors.red)
                            .withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        isConnection
                            ? Icons.wifi_off_rounded
                            : Icons.dns_rounded,
                        color: isConnection
                            ? AppColors.amber
                            : AppColors.red,
                        size: 32,
                      ),
                    ),
                    // Small decorative dot
                    Positioned(
                      top: 18,
                      right: 22,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isConnection
                                  ? AppColors.amber
                                  : AppColors.red)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Title + subtitle
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Text(
                    isConnection ? 'You\'re Offline' : 'Oops! Server Hiccup',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isConnection
                        ? 'Looks like your internet took a break.\nCheck your connection and we\'ll be right back.'
                        : 'Our servers are taking a quick nap.\nDon\'t worry, we\'ll be back shortly.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Retry button
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: widget.onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtle hint
                  Text(
                    isConnection
                        ? 'Pull down to refresh when you\'re back online'
                        : 'Usually resolves in a few seconds',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
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

class _OrdersShimmer extends StatelessWidget {
  const _OrdersShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerOrderCard(),
      ),
    );
  }
}
