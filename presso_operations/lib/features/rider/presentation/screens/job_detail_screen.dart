import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';
import 'package:presso_operations/features/rider/presentation/providers/jobs_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const JobDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          jobAsync.asData?.value.order?.orderNumber != null
              ? '#${jobAsync.asData!.value.order!.orderNumber}'
              : 'Pickup Job',
          style: const TextStyle(
              color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Color(0xFF0891B2)),
            onPressed: () {
              final phone = jobAsync.asData?.value.customer?.maskedPhone;
              if (phone != null && phone.isNotEmpty) {
                launchUrl(Uri.parse('tel:$phone'));
              }
            },
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load job',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    jobDetailProvider(widget.assignmentId)),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        data: (job) => _buildContent(job),
      ),
    );
  }

  Widget _buildContent(AssignmentModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMapPlaceholder(job),
          const SizedBox(height: 16),
          _buildCustomerCard(job),
          const SizedBox(height: 16),
          _buildOrderItemsCard(job),
          if (job.order?.specialInstructions != null &&
              job.order!.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSpecialInstructions(job.order!.specialInstructions!),
          ],
          if (job.order?.hasShoeItems == true &&
              (job.order?.shoeItems.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _buildShoeItemsCard(job.order!.shoeItems),
          ],
          const SizedBox(height: 24),
          _buildAcceptPickupButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(AssignmentModel job) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.primary, size: 40),
                const SizedBox(height: 8),
                Text(
                  job.address?.fullAddress ?? 'Location',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (job.address?.latitude != null &&
                    job.address?.longitude != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${job.address!.latitude!.toStringAsFixed(4)}, ${job.address!.longitude!.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: IntrinsicWidth(
              child: ElevatedButton.icon(
                onPressed: () {
                  final lat = job.address?.latitude;
                  final lng = job.address?.longitude;
                  if (lat != null && lng != null) {
                    final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Navigate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(AssignmentModel job) {
    final name = job.customer?.name ?? 'Customer';
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.customer?.maskedPhone ?? '',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final phone = job.customer?.maskedPhone;
                  if (phone != null && phone.isNotEmpty) {
                    launchUrl(Uri.parse('tel:$phone'));
                  }
                },
                icon: const Icon(Icons.phone, color: AppColors.green),
                tooltip: 'Call',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (job.address?.label != null && job.address!.label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                job.address!.label!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            job.address?.fullAddress ?? 'No address',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(AssignmentModel job) {
    final order = job.order;
    final garmentCount = order?.garmentCount ?? 0;
    final service = order?.serviceSummary;
    final subtitle = service != null && service.isNotEmpty
        ? '$garmentCount garments · $service'
        : '$garmentCount garments';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (order?.isExpressDelivery == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt, size: 13, color: AppColors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Express',
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                '#${order?.orderNumber ?? ''}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(String instructions) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer note',
                  style: TextStyle(
                    color: AppColors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructions,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoeItemsCard(List<ShoeItemModel> shoeItems) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cleaning_services_outlined,
                  color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Shoe Items',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${shoeItems.length} ${shoeItems.length == 1 ? 'pair' : 'pairs'}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...shoeItems.map((shoe) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shoe.shoeType ?? 'Shoe',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\u20b9${shoe.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shoe.treatmentType ?? ''} \u2022 ${shoe.pairCount} pair(s)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (shoe.bagLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Bag: ${shoe.bagLabel}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (shoe.specialInstructions != null &&
                        shoe.specialInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        shoe.specialInstructions!,
                        style: const TextStyle(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Screen 3: "Accept Pickup" just advances to the navigation screen — the
  // assignment is already Accepted server-side via the offer flow. The
  // markArrived API call happens on the NavigateScreen's "I've Arrived" button.
  Widget _buildAcceptPickupButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/rider/job/${widget.assignmentId}/navigate');
        },
        icon: const Icon(Icons.check_circle_outline, size: 22),
        label: const Text(
          'Accept Pickup',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
