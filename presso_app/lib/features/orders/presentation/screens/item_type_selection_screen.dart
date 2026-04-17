import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';

class ItemTypeSelectionScreen extends ConsumerWidget {
  final String serviceId;
  const ItemTypeSelectionScreen({super.key, required this.serviceId});

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
          title: const Text('Select Items', style: AppTextStyles.heading3),
        ),
        body: const Center(child: Text('Service not found')),
      );
    }

    final garmentTypes = service.garmentTypes;

    // Count selected garment types for this service
    int selectedCount = 0;
    for (final g in garmentTypes) {
      final key = '${serviceId}_${g.id}';
      if ((flowState.garmentCounts[key] ?? 0) > 0) {
        selectedCount++;
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What would you like cleaned?',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: garmentTypes.map((garmentType) {
                final key = '${serviceId}_${garmentType.id}';
                final isSelected = (flowState.garmentCounts[key] ?? 0) > 0;
                final price = garmentType.priceOverride ?? service.pricePerPiece;

                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      notifier.setGarmentCount(serviceId: serviceId, garmentTypeId: garmentType.id, count: 0);
                    } else {
                      notifier.setGarmentCount(serviceId: serviceId, garmentTypeId: garmentType.id, count: 1);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Checkmark in top-right corner
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, size: 14, color: AppColors.background),
                            ),
                          ),

                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Emoji or CircleAvatar fallback
                              if (garmentType.emoji != null)
                                Text(
                                  garmentType.emoji!,
                                  style: const TextStyle(fontSize: 36),
                                )
                              else
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  child: Text(
                                    garmentType.name.isNotEmpty ? garmentType.name[0].toUpperCase() : '?',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Garment type name
                              Text(
                                garmentType.name,
                                style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // Price
                              Text(
                                '\u{20B9}${price.toStringAsFixed(0)}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
                  child: Text(
                    '$selectedCount item type${selectedCount == 1 ? '' : 's'} selected',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                PressoButton(
                  label: 'Next',
                  trailingIcon: Icons.arrow_forward_rounded,
                  width: 120,
                  height: 44,
                  onPressed: selectedCount > 0
                      ? () => context.push('/order/treatment/$serviceId/pick')
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
