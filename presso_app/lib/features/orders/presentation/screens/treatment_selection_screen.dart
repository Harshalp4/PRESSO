import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';
import 'package:presso_app/features/services/domain/models/service_treatment_model.dart';

class TreatmentSelectionScreen extends ConsumerWidget {
  final String serviceId;
  const TreatmentSelectionScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);
    final notifier = ref.read(createOrderFlowProvider.notifier);

    final service = flowState.selectedServices.cast<ServiceModel?>().firstWhere(
      (s) => s!.id == serviceId,
      orElse: () => null,
    );

    if (service == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Select Treatment', style: AppTextStyles.heading3),
        ),
        body: const Center(child: Text('Service not found')),
      );
    }

    final treatments = service.treatments;
    // Only show garment types that were selected in Screen 1 (count > 0)
    final selectedGarments = service.garmentTypes.where((g) {
      final key = '${service.id}_${g.id}';
      return (flowState.garmentCounts[key] ?? 0) > 0;
    }).toList();

    // Calculate running total for this service
    double runningTotal = 0;
    int serviceItemCount = 0;
    for (final g in selectedGarments) {
      final key = '${service.id}_${g.id}';
      final qty = flowState.garmentCounts[key] ?? 0;
      if (qty > 0) {
        serviceItemCount += qty;
        final basePrice = g.priceOverride ?? service.pricePerPiece;
        final treatmentId = flowState.treatmentSelections[key];
        final treatment = treatmentId != null
            ? treatments.cast<ServiceTreatmentModel?>().firstWhere((t) => t!.id == treatmentId, orElse: () => null)
            : null;
        final multiplier = treatment?.priceMultiplier ?? 1.0;
        runningTotal += basePrice * multiplier * qty;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(service.name, style: AppTextStyles.heading3),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'Select treatment tier and quantity for each item.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: selectedGarments.length,
              itemBuilder: (context, index) {
                final garment = selectedGarments[index];
                final key = '${service.id}_${garment.id}';
                final count = flowState.garmentCounts[key] ?? 0;
                final selectedTreatmentId = flowState.treatmentSelections[key];
                final basePrice = garment.priceOverride ?? service.pricePerPiece;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Garment header with emoji + quantity
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(
                          children: [
                            // Emoji
                            if (garment.emoji != null && garment.emoji!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(garment.emoji!, style: const TextStyle(fontSize: 22)),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    garment.name,
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'from \u{20B9}${basePrice.toStringAsFixed(0)}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity counter
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: count > 1
                                      ? () => notifier.decrementGarment(serviceId: service.id, garmentTypeId: garment.id)
                                      : null,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: count <= 1 ? AppColors.surfaceLight : AppColors.primary.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: count <= 1 ? AppColors.border : AppColors.primary.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Icon(Icons.remove_rounded, size: 18,
                                        color: count <= 1 ? AppColors.textHint : AppColors.primary),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    count.toString(),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => notifier.incrementGarment(serviceId: service.id, garmentTypeId: garment.id),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_rounded, size: 18, color: AppColors.background),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Treatment tiers
                      if (treatments.isNotEmpty) ...[
                        const Divider(color: AppColors.divider, height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TREATMENT',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...treatments.map((t) {
                                final isSelected = selectedTreatmentId == t.id;
                                final itemPrice = basePrice * t.priceMultiplier;
                                return GestureDetector(
                                  onTap: () => notifier.setTreatment(
                                    serviceId: service.id,
                                    garmentTypeId: garment.id,
                                    treatmentId: isSelected ? null : t.id,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                        width: isSelected ? 1.5 : 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected ? AppColors.primary : AppColors.textHint,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.background)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    t.name,
                                                    style: AppTextStyles.body.copyWith(
                                                      fontSize: 13,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\u{20B9}${itemPrice.toStringAsFixed(0)}',
                                                    style: AppTextStyles.body.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (t.description != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    t.description!,
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              // Tag chips
                                              if (t.tags.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: t.tags.map((tag) {
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'est. \u{20B9}${runningTotal.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$serviceItemCount items',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PressoButton(
                  label: 'Review',
                  trailingIcon: Icons.arrow_forward_rounded,
                  width: 130,
                  height: 44,
                  onPressed: serviceItemCount > 0
                      ? () {
                          context.push('/order/treatment/$serviceId/summary');
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
