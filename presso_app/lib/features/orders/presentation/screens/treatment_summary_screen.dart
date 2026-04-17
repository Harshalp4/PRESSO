import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/domain/models/garment_type_model.dart';
import 'package:presso_app/features/services/domain/models/service_treatment_model.dart';

class TreatmentSummaryScreen extends ConsumerWidget {
  final String serviceId;

  const TreatmentSummaryScreen({
    super.key,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);

    final service = flowState.selectedServices.firstWhere(
      (s) => s.id == serviceId,
    );

    // Build line items
    final lineItems = <_LineItem>[];
    for (final garment in service.garmentTypes) {
      final key = '${service.id}_${garment.id}';
      final qty = flowState.garmentCounts[key] ?? 0;
      if (qty == 0) continue;

      final treatmentId = flowState.treatmentSelections[key];
      final ServiceTreatmentModel? treatment = treatmentId != null
          ? service.treatments.cast<ServiceTreatmentModel?>().firstWhere(
                (t) => t?.id == treatmentId,
                orElse: () => null,
              )
          : null;

      final basePrice = garment.priceOverride ?? service.pricePerPiece;
      final multiplier = treatment?.priceMultiplier ?? 1.0;
      final unitPrice = basePrice * multiplier;
      final lineTotal = unitPrice * qty;

      lineItems.add(_LineItem(
        garment: garment,
        treatment: treatment,
        qty: qty,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
      ));
    }

    final serviceTotal =
        lineItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final totalQty = lineItems.fold<int>(0, (sum, item) => sum + item.qty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review \u2014 ${service.name}',
          style: AppTextStyles.heading3,
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          ...lineItems.map((item) => _buildLineItemCard(item)),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                '\u{20B9}${serviceTotal.toStringAsFixed(0)}',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Container(
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u{20B9}${serviceTotal.toStringAsFixed(0)}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalQty items',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PressoButton(
              label: 'Continue',
              trailingIcon: Icons.arrow_forward_rounded,
              width: 130,
              height: 44,
              onPressed: () => _onContinue(context, flowState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemCard(_LineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: garment name + quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (item.garment.emoji != null &&
                      item.garment.emoji!.isNotEmpty)
                    Text(item.garment.emoji!,
                        style: const TextStyle(fontSize: 18))
                  else
                    const Icon(Icons.checkroom,
                        color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    item.garment.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '\u00D7${item.qty}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Treatment info
          if (item.treatment != null) ...[
            const SizedBox(height: 8),
            Text(
              item.treatment!.name,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (item.treatment!.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.treatment!.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],

          // Bottom row: unit price x qty on left, line total on right
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\u{20B9}${item.unitPrice.toStringAsFixed(0)} \u00D7 ${item.qty}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '\u{20B9}${item.lineTotal.toStringAsFixed(0)}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onContinue(BuildContext context, CreateOrderFlowState flowState) {
    // Find all treatment services
    final treatmentServices = flowState.selectedServices
        .where((s) => s.hasTreatments)
        .toList();
    final currentIndex =
        treatmentServices.indexWhere((s) => s.id == serviceId);

    if (currentIndex < treatmentServices.length - 1) {
      // More treatment services — go to next one's Screen 1
      final nextService = treatmentServices[currentIndex + 1];
      context.push('/order/treatment/${nextService.id}/types');
    } else {
      // All treatment services done
      final hasNonTreatmentServices =
          flowState.selectedServices.any((s) => !s.hasTreatments);
      if (hasNonTreatmentServices) {
        context.push('/order/garments');
      } else if (flowState.hasEnoughItems) {
        context.push('/order/slots');
      } else {
        context.push('/order/garments');
      }
    }
  }
}

class _LineItem {
  final GarmentTypeModel garment;
  final ServiceTreatmentModel? treatment;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  const _LineItem({
    required this.garment,
    required this.treatment,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });
}
