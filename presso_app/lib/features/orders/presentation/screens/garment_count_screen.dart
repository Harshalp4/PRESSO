import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/data/services_repository.dart';
import 'package:presso_app/features/services/domain/models/fallback_services.dart';
import 'package:presso_app/features/services/domain/models/garment_type_model.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';
import 'package:presso_app/features/home/presentation/providers/home_provider.dart';

// ─── Emoji helpers ──────────────────────────────────────────────────────────

String _emojiForGarment(GarmentTypeModel garment) {
  if (garment.emoji != null && garment.emoji!.isNotEmpty) return garment.emoji!;
  final n = garment.name.toLowerCase();
  if (n.contains('shirt')) return '\u{1F455}';
  if (n.contains('pant') || n.contains('jeans')) return '\u{1F456}';
  if (n.contains('kurta') || n.contains('saree') || n.contains('lehenga')) return '\u{1F97B}';
  if (n.contains('suit') || n.contains('blazer')) return '\u{1F935}';
  if (n.contains('jacket') || n.contains('coat')) return '\u{1F9E5}';
  if (n.contains('bedsheet') || n.contains('bed')) return '\u{1F6CF}\u{FE0F}';
  if (n.contains('pillow')) return '\u{1F6CC}';
  if (n.contains('towel')) return '\u{1F9F4}';
  if (n.contains('curtain')) return '\u{1FA9F}';
  if (n.contains('silk')) return '\u{1F9F5}';
  if (n.contains('wool')) return '\u{1F9F6}';
  if (n.contains('delicate')) return '\u{1F9F5}';
  if (n.contains('sweater')) return '\u{1F9E3}';
  if (n.contains('blanket')) return '\u{1F9E3}';
  if (n.contains('sneaker')) return '\u{1F45F}';
  if (n.contains('sandal')) return '\u{1FA74}';
  if (n.contains('heel')) return '\u{1F460}';
  if (n.contains('boot')) return '\u{1F97E}';
  if (n.contains('shoe')) return '\u{1F45E}';
  if (n.contains('bag') || n.contains('backpack')) return '\u{1F392}';
  if (n.contains('wallet') || n.contains('belt')) return '\u{1F45B}';
  if (n.contains('handbag') || n.contains('purse')) return '\u{1F45C}';
  return '\u{1F455}';
}

String _emojiForService(ServiceModel service) {
  if (service.emoji != null && service.emoji!.isNotEmpty) return service.emoji!;
  final n = service.name.toLowerCase();
  if (n.contains('wash') && n.contains('iron')) return '\u{1F455}';
  if (n.contains('wash') && n.contains('fold')) return '\u{1F454}';
  if (n.contains('dry')) return '\u{2728}';
  if (n.contains('iron')) return '\u{2668}\u{FE0F}';
  if (n.contains('premium') || n.contains('hand wash')) return '\u{1F9F6}';
  if (n.contains('bedsheet') || n.contains('pillow')) return '\u{1F6CC}';
  if (n.contains('curtain')) return '\u{1FA9F}';
  if (n.contains('saree') || n.contains('ethnic')) return '\u{1F97B}';
  if (n.contains('woolen') || n.contains('winter')) return '\u{1F9E3}';
  if (n.contains('bag') || n.contains('leather')) return '\u{1F45C}';
  if (n.contains('shoe')) return '\u{1F45F}';
  return '\u{1F455}';
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class GarmentCountScreen extends ConsumerWidget {
  const GarmentCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);
    final notifier = ref.read(createOrderFlowProvider.notifier);
    final regularServices =
        flowState.selectedServices.where((s) => !s.hasTreatments).toList();
    final treatmentServices =
        flowState.selectedServices.where((s) => s.hasTreatments).toList();

    final totalPcs = flowState.totalItemCount;
    final subtotal = flowState.subtotal;
    final hasMinItems = flowState.hasEnoughItems;

    // Coin balance for summary
    final coinAsync = ref.watch(coinBalanceProvider);
    final coinBalance = coinAsync.valueOrNull?.balance ?? 0;
    final coinsToRedeem = coinBalance.clamp(0, 50);
    final coinValue = coinsToRedeem * 0.1;

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
        title: const Text('Your Cart', style: AppTextStyles.heading3),
        titleSpacing: 0,
        actions: [
          if (totalPcs > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  '$totalPcs items',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _showEditServicesSheet(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Services',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Treatment-based services ──
                ...treatmentServices.map((service) {
                  int itemCount = 0;
                  double serviceTotal = 0;
                  String treatmentLabel = '';
                  for (final g in service.garmentTypes) {
                    final key = '${service.id}_${g.id}';
                    final qty = flowState.garmentCounts[key] ?? 0;
                    if (qty > 0) {
                      itemCount += qty;
                      final basePrice = g.priceOverride ?? service.pricePerPiece;
                      final treatmentId = flowState.treatmentSelections[key];
                      final treatment = treatmentId != null
                          ? service.treatments.cast<dynamic>().firstWhere(
                              (t) => t.id == treatmentId, orElse: () => null)
                          : null;
                      final multiplier = treatment?.priceMultiplier ?? 1.0;
                      serviceTotal += basePrice * multiplier * qty;
                      if (treatment != null && treatmentLabel.isEmpty) {
                        treatmentLabel = ' \u{00B7} ${treatment.name}';
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          '${service.name}$treatmentLabel'.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/order/treatment/${service.id}/types'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: itemCount > 0 ? AppColors.primary : AppColors.border,
                              width: itemCount > 0 ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(_emojiForService(service), style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      itemCount > 0
                                          ? '$itemCount item${itemCount == 1 ? '' : 's'} \u{00B7} \u{20B9}${serviceTotal.toStringAsFixed(0)}'
                                          : 'Tap to select items & treatment',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: itemCount > 0 ? AppColors.green : AppColors.textSecondary,
                                        fontWeight: itemCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),

                // ── Regular services (inline garment pickers) ──
                ...regularServices.map((service) => _ServiceSection(
                  service: service,
                  garmentCounts: flowState.garmentCounts,
                  onIncrement: (id) => notifier.incrementGarment(serviceId: service.id, garmentTypeId: id),
                  onDecrement: (id) => notifier.decrementGarment(serviceId: service.id, garmentTypeId: id),
                )),

                // ── Summary card (matching mockup) ──
                if (totalPcs > 0) ...[
                  const SizedBox(height: 8),
                  _SummaryCard(totalPcs: totalPcs, subtotal: subtotal, coinsRedeemed: coinsToRedeem, coinValue: coinValue),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
          _BottomBar(
            hasMinItems: hasMinItems,
            onNext: hasMinItems ? () => context.push('/order/slots') : null,
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int totalPcs;
  final double subtotal;
  final int coinsRedeemed;
  final double coinValue;

  const _SummaryCard({required this.totalPcs, required this.subtotal, required this.coinsRedeemed, required this.coinValue});

  @override
  Widget build(BuildContext context) {
    final total = subtotal - coinValue;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        children: [
          _row('Subtotal ($totalPcs items)', '\u{20B9}${subtotal.toStringAsFixed(0)}', AppColors.textPrimary),
          const SizedBox(height: 6),
          if (coinsRedeemed > 0) ...[
            _row('Coins redeemed (-$coinsRedeemed)', '-\u{20B9}${coinValue.toStringAsFixed(0)}', AppColors.green),
            const SizedBox(height: 6),
          ],
          _row('Delivery', 'FREE', AppColors.green),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('\u{20B9}${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

// ─── Edit Services bottom sheet ──────────────────────────────────────────────

void _showEditServicesSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
      builder: (context, sc) => _EditServicesSheet(scrollController: sc, parentRef: ref),
    ),
  );
}

class _EditServicesSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final WidgetRef parentRef;
  const _EditServicesSheet({required this.scrollController, required this.parentRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);
    final notifier = ref.read(createOrderFlowProvider.notifier);
    final selectedIds = flowState.selectedServices.map((s) => s.id).toSet();
    final servicesAsync = ref.watch(_allServicesProvider);

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Edit Services', style: AppTextStyles.heading3.copyWith(fontSize: 16)),
              const Spacer(),
              Text('${selectedIds.length} selected', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),
        Expanded(
          child: servicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => Center(child: Text('Could not load services', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
            data: (services) => ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = selectedIds.contains(service.id);
                return GestureDetector(
                  onTap: () => notifier.toggleService(service),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.textHint, width: 1.5),
                          ),
                          child: isSelected ? const Icon(Icons.check_rounded, size: 14, color: AppColors.background) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('From \u{20B9}${service.pricePerPiece.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textHint, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
          child: SizedBox(width: double.infinity, child: PressoButton(label: 'Done', height: 44, onPressed: selectedIds.isNotEmpty ? () => Navigator.pop(context) : null)),
        ),
      ],
    );
  }
}

final _allServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  final result = await repo.getServices();
  if (result.success && result.data != null && result.data!.isNotEmpty) return result.data!;
  return kFallbackServices;
});

// ─── Service section — mockup: sec-title → card with garment rows ───────────

class _ServiceSection extends StatelessWidget {
  final ServiceModel service;
  final Map<String, int> garmentCounts;
  final void Function(String) onIncrement;
  final void Function(String) onDecrement;

  const _ServiceSection({required this.service, required this.garmentCounts, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final sorted = List<GarmentTypeModel>.from(service.garmentTypes)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(service.name.toUpperCase(), style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
          child: Column(
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                _GarmentRow(
                  garment: sorted[i],
                  count: garmentCounts['${service.id}_${sorted[i].id}'] ?? 0,
                  pricePerPiece: sorted[i].priceOverride ?? service.pricePerPiece,
                  basePrice: service.pricePerPiece,
                  onIncrement: () => onIncrement(sorted[i].id),
                  onDecrement: () => onDecrement(sorted[i].id),
                ),
                if (i < sorted.length - 1) const Divider(height: 0.5, color: AppColors.divider, indent: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Garment row ─────────────────────────────────────────────────────────────

class _GarmentRow extends StatelessWidget {
  final GarmentTypeModel garment;
  final int count;
  final double pricePerPiece;
  final double basePrice;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _GarmentRow({required this.garment, required this.count, required this.pricePerPiece, required this.basePrice, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;
    final isPremium = pricePerPiece > basePrice;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(garment.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          Text('\u{20B9}${pricePerPiece.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isPremium ? AppColors.amber : AppColors.textSecondary)),
          const SizedBox(width: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isZero ? null : onDecrement,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text('\u{2212}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isZero ? AppColors.textHint : AppColors.primary)),
                ),
              ),
              SizedBox(width: 28, child: Text(count.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool hasMinItems;
  final VoidCallback? onNext;
  const _BottomBar({required this.hasMinItems, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: onNext != null ? const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)]) : null,
              color: onNext == null ? AppColors.textHint : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: onNext != null ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))] : null,
            ),
            child: Text(
              'Select Pickup Slot \u{2192}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onNext != null ? Colors.white : Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
