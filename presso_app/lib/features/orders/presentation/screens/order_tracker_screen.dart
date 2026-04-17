import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/features/orders/domain/models/order_detail_model.dart';
import 'package:presso_app/features/orders/presentation/providers/order_provider.dart';

class OrderTrackerScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackerScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: orderAsync.when(
        loading: () => _buildAppBar('Track Order', ''),
        error: (_, __) => _buildAppBar('Track Order', ''),
        data: (order) => _buildAppBar('Track Order', order.orderNumber),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load order',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (order) => _TrackerContent(order: order),
      ),
    );
  }

  AppBar _buildAppBar(String title, String orderNumber) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      title: Text(title, style: AppTextStyles.heading3),
      titleSpacing: 0,
      actions: [
        if (orderNumber.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                orderNumber,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackerContent extends StatelessWidget {
  final OrderDetailModel order;

  const _TrackerContent({required this.order});

  // Timeline steps:
  //   0 Picked up    1 At facility    2 Processing    3 Out for delivery    4 Delivered
  //
  // The backend returns OrderStatus ("PickedUp", "InProcess", "ReadyForDelivery",
  // "OutForDelivery", "Delivered") alongside a FacilityStage sub-bucket
  // ("AtFacility" / "Washing" / "Ironing" / "Ready"). OrderDetailModel.effectiveStatus
  // flattens those so "InProcess" expands into the actual facility sub-stage
  // we need here. We also accept the legacy snake_case and PascalCase spellings
  // so older cached responses and the rider/facility apps stay in sync.
  int get _currentStep {
    switch (order.effectiveStatus) {
      case 'pending':
      case 'confirmed':
      case 'riderassigned':
      case 'rider_assigned':
      case 'pickupinprogress':
        return -1;
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
        return 2;
      case 'ready':
      case 'readyfordelivery':
      case 'ready_for_delivery':
        // "Ready" is the transitional state between Processing done and the
        // rider actually picking up the bag for delivery — treat it as the
        // tail of Processing (keeps "Out for delivery" unticked until a
        // delivery rider is on the road).
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

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStep;
    final rider = order.assignments.where((a) => a.role == 'rider').firstOrNull;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery OTP banner — only surfaces while the order is Out for
          // Delivery. Rider needs to type this 4-digit code to confirm the
          // handoff at the door.
          if (order.deliveryOtp != null && order.deliveryOtp!.isNotEmpty)
            _DeliveryOtpBanner(otp: order.deliveryOtp!),
          // Map placeholder
          Container(
            margin: const EdgeInsets.all(16),
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined,
                          color: AppColors.textSecondary, size: 36),
                      SizedBox(height: 8),
                      Text(
                        '[ Live map · rider location ]',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pickup photos
          if (order.pickupPhotoUrls.isNotEmpty)
            _PickupPhotosSection(
              photoUrls: order.pickupPhotoUrls,
              orderId: order.id,
              agentName: rider?.agentName ?? 'Rider',
              itemCount: order.totalItemCount,
            ),

          // Timeline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Timeline(currentStep: currentStep, order: order),
          ),
          const SizedBox(height: 16),

          // Rider card
          if (rider != null)
            _RiderCard(assignment: rider),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PickupPhotosSection extends StatelessWidget {
  final List<String> photoUrls;
  final String orderId;
  final String agentName;
  final int itemCount;

  const _PickupPhotosSection({
    required this.photoUrls,
    required this.orderId,
    required this.agentName,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayPhotos = photoUrls.take(4).toList();
    final remaining = photoUrls.length - displayPhotos.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup photos · $agentName collected $itemCount items',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...displayPhotos.map((url) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(url),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )),
              if (remaining > 0)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                context.push('/order/$orderId/photos', extra: photoUrls),
            child: Text(
              'View all photos →',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final int currentStep;
  final OrderDetailModel order;

  const _Timeline({required this.currentStep, required this.order});

  @override
  Widget build(BuildContext context) {
    // Choose a descriptive line for "Processing" based on the exact facility
    // sub-stage the backend returned, so the customer sees washing/ironing/
    // ready rather than a generic "in progress" copy.
    String processingSubtitle() {
      final stage = order.facilityStage?.toLowerCase();
      if (currentStep > 2 || order.effectiveStatus == 'delivered' ||
          order.effectiveStatus == 'outfordelivery' ||
          order.effectiveStatus == 'out_for_delivery') {
        return order.readyAt != null
            ? 'Ready · ${_formatTime(order.readyAt!)}'
            : 'Completed';
      }
      if (currentStep < 2) return 'Pending';
      switch (stage) {
        case 'washing':
          return 'Washing in progress';
        case 'ironing':
          return 'Ironing in progress';
        case 'ready':
          return order.readyAt != null
              ? 'Ready · ${_formatTime(order.readyAt!)}'
              : 'Ready for delivery';
        default:
          return 'In progress · your items are being serviced';
      }
    }

    final steps = [
      _TimelineStep(
        label: 'Picked up',
        subtitle: order.pickedUpAt != null
            ? '${_formatTime(order.pickedUpAt!)} · ${order.assignments.where((a) => a.role == 'rider').firstOrNull?.agentName ?? 'Rider'} collected ${order.totalItemCount} items'
            : 'Waiting for pickup',
        isCompleted: currentStep >= 0,
        isActive: currentStep == 0,
      ),
      _TimelineStep(
        label: 'At facility',
        subtitle: currentStep >= 1
            ? (order.facilityReceivedAt != null
                ? 'Received · ${_formatTime(order.facilityReceivedAt!)}'
                : 'Received at facility')
            : 'Pending',
        isCompleted: currentStep >= 1,
        isActive: currentStep == 1,
      ),
      _TimelineStep(
        label: 'Processing',
        subtitle: processingSubtitle(),
        isCompleted: currentStep > 2,
        isActive: currentStep == 2,
        isPulsing: currentStep == 2,
      ),
      _TimelineStep(
        label: 'Out for delivery',
        subtitle: currentStep >= 3
            ? (order.outForDeliveryAt != null
                ? 'On the way · ${_formatTime(order.outForDeliveryAt!)}'
                : 'On the way')
            : 'Pending',
        isCompleted: currentStep >= 3,
        isActive: currentStep == 3,
      ),
      _TimelineStep(
        label: 'Delivered',
        subtitle: currentStep >= 4 && order.deliveredAt != null
            ? _formatTime(order.deliveredAt!)
            : 'Pending',
        isCompleted: currentStep >= 4,
        isActive: currentStep == 4,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + line column
            Column(
              children: [
                _StepCircle(
                  isCompleted: step.isCompleted,
                  isActive: step.isActive,
                  isPulsing: step.isPulsing,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: step.isCompleted
                        ? AppColors.green
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      step.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted || step.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      step.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: step.isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _TimelineStep {
  final String label;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isPulsing;

  const _TimelineStep({
    required this.label,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
    this.isPulsing = false,
  });
}

class _StepCircle extends StatefulWidget {
  final bool isCompleted;
  final bool isActive;
  final bool isPulsing;

  const _StepCircle({
    required this.isCompleted,
    required this.isActive,
    this.isPulsing = false,
  });

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            size: 14, color: Colors.white),
      );
    }

    if (widget.isActive && widget.isPulsing) {
      return ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.hourglass_top_rounded,
              size: 12, color: AppColors.primary),
        ),
      );
    }

    if (widget.isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  final OrderAssignment assignment;

  const _RiderCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: assignment.profilePhotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      assignment.profilePhotoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      assignment.agentName.isNotEmpty
                          ? assignment.agentName[0].toUpperCase()
                          : 'R',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${assignment.agentName} · ${assignment.role.capitalize()}',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (assignment.vehicleNumber != null)
                  Text(
                    assignment.vehicleNumber!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                if (assignment.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppColors.amber),
                      const SizedBox(width: 2),
                      Text(
                        assignment.rating!.toStringAsFixed(1),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Call button
          if (assignment.agentPhone != null)
            GestureDetector(
              onTap: () {
                // Launch phone call
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.green.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.green,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

// Prominent banner that shows the 4-digit delivery OTP the rider needs to
// confirm handoff. Rendered as a gradient card with big tabular-figure
// digits so the rider can read it from a phone held at arm's length.
class _DeliveryOtpBanner extends StatelessWidget {
  final String otp;
  const _DeliveryOtpBanner({required this.otp});

  @override
  Widget build(BuildContext context) {
    final digits = otp.split('');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'SHOW THIS CODE TO THE RIDER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits
                .map(
                  (d) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 48,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Color(0xFF0891B2),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your rider will ask for this code at the door.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
