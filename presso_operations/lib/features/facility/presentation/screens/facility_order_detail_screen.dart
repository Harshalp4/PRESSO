import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_detail_model.dart';
import 'package:presso_operations/features/facility/presentation/providers/facility_provider.dart';

class FacilityOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const FacilityOrderDetailScreen({super.key, required this.orderId});

  Color _statusColor(String status) {
    switch (status) {
      case 'AtFacility':
        return AppColors.primary;
      case 'Washing':
        return const Color(0xFF00E5FF);
      case 'Ironing':
        return AppColors.amber;
      case 'Ready':
        return AppColors.green;
      case 'PickedUp':
        return AppColors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'AtFacility':
        return 'At Facility';
      case 'Washing':
        return 'Washing';
      case 'Ironing':
        return 'Ironing';
      case 'Ready':
        return 'Ready';
      case 'PickedUp':
        return 'Picked Up';
      default:
        return status;
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'AtFacility':
        return 'Washing';
      case 'Washing':
        return 'Ironing';
      case 'Ironing':
        return 'Ready';
      default:
        return null;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(facilityOrderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: detailAsync.whenOrNull(
          data: (detail) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                detail.orderNumber,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(detail.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(detail.status),
                  style: TextStyle(
                    color: _statusColor(detail.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load order',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(facilityOrderDetailProvider(orderId)),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (detail) => _buildContent(context, detail),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FacilityOrderDetailModel detail) {
    final next = _nextStatus(detail.status);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer info
              _buildSection(
                'Customer Information',
                Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Customer', detail.customerName),
                    _infoRow('Order Date', _formatDate(detail.createdAt)),
                    if (detail.pickupSlotDisplay != null)
                      _infoRow('Pickup Time', detail.pickupSlotDisplay!),
                    if (detail.isExpressDelivery)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt,
                                  size: 14, color: AppColors.red),
                              SizedBox(width: 4),
                              Text('Express Delivery',
                                  style: TextStyle(
                                      color: AppColors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Garments section
              _buildSection(
                'Garments (${detail.garmentCount})',
                Icons.checkroom,
                child: Column(
                  children: detail.items
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.garmentTypeName,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${item.serviceName}${item.treatmentName != null ? ' - ${item.treatmentName}' : ''}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Special instructions
              if (detail.specialInstructions != null &&
                  detail.specialInstructions!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.amber.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.amber),
                          SizedBox(width: 6),
                          Text(
                            'Special Instructions',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.specialInstructions!,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Pickup photos
              if (detail.pickupPhotoUrls.isNotEmpty) ...[
                _buildSection(
                  '${detail.pickupPhotoUrls.length} photos taken by rider',
                  Icons.photo_library_outlined,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: detail.pickupPhotoUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          detail.pickupPhotoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: Icon(Icons.broken_image,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Shoe section
              if (detail.hasShoeItems && detail.shoeItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 18, color: AppColors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Shoe Items',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...detail.shoeItems.map(
                          (shoe) => _buildShoeItem(shoe)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Timeline
              _buildSection(
                'Status Timeline',
                Icons.timeline,
                child: Column(
                  children: detail.timeline
                      .asMap()
                      .entries
                      .map((entry) => _buildTimelineItem(
                            entry.value,
                            isLast:
                                entry.key == detail.timeline.length - 1,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),

        // Wireframe screen 14 — when the order is Ready, the next action is
        // dispatching a delivery rider, not a status change.
        if (detail.status == 'Ready')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => GoRouter.of(context).push(
                    '/facility/order/$orderId/dispatch',
                    extra: detail.orderNumber,
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Dispatch for Delivery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          )
        // Bottom status update section
        else if (next != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current: ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        _statusLabel(detail.status),
                        style: TextStyle(
                          color: _statusColor(detail.status),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => GoRouter.of(context)
                          .push('/facility/order/$orderId/status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusColor(next),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Move to ${_statusLabel(next)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoeItem(ShoeItemModel shoe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe.shoeType,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${shoe.treatmentType} - ${shoe.pairCount} pair(s)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(shoe.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(shoe.status),
                  style: TextStyle(
                    color: _statusColor(shoe.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (shoe.bagLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bag: ${shoe.bagLabel}',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          if (shoe.specialInstructions != null &&
              shoe.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              shoe.specialInstructions!,
              style: const TextStyle(
                  color: AppColors.amber, fontSize: 12),
            ),
          ],
          if (shoe.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shoe.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    shoe.photoUrls[i],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.surfaceLight,
                      child: Icon(Icons.broken_image,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEntry entry, {bool isLast = false}) {
    final color = _statusColor(entry.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(entry.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.timestamp),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
