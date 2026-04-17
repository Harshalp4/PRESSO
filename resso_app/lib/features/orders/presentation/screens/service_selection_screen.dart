import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/constants/app_text_styles.dart';
import 'package:presso_app/core/widgets/presso_button.dart';
import 'package:presso_app/core/widgets/shimmer_loader.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import 'package:presso_app/features/services/data/services_repository.dart';
import 'package:presso_app/features/services/domain/models/fallback_services.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';

// ─── Category filter ──────────────────────────────────────────────────────────

const _categories = ['All', 'Clothes', 'Home linen', 'Specialty'];

// ─── Main screen ──────────────────────────────────────────────────────────────

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  String _activeCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(_servicesProvider);
    final flowState = ref.watch(createOrderFlowProvider);
    final flowNotifier = ref.read(createOrderFlowProvider.notifier);
    final selectedIds = flowState.selectedServices.map((s) => s.id).toSet();

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
        title: const Text('Select Services', style: AppTextStyles.heading3),
        titleSpacing: 0,
        actions: [
          if (flowState.selectedServices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  '${flowState.selectedServices.length} selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'What do you need? Select one or more.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),

          // Category tabs (matching mockup tab-row style)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: _categories.map((cat) {
                final active = _activeCategory == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        cat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Services grid — 2-column matching mockup svc-grid
          Expanded(
            child: servicesAsync.when(
              loading: () => const _ServicesShimmer(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load services',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              data: (services) {
                final grouped = _groupServices(services, _activeCategory);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped[index];
                    if (entry is _SectionHeaderData) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                            16, index == 0 ? 2 : 14, 16, 8),
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      );
                    }
                    if (entry is _ServiceGridRow) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            for (var i = 0; i < entry.services.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _ServiceGridCard(
                                  service: entry.services[i],
                                  isSelected: selectedIds
                                      .contains(entry.services[i].id),
                                  onTap: () => flowNotifier
                                      .toggleService(entry.services[i]),
                                ),
                              ),
                            ],
                            // Fill empty space if odd number
                            if (entry.services.length == 1) ...[
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox()),
                            ],
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),

          // Bottom bar
          _BottomBar(
            selectedCount: flowState.selectedServices.length,
            onNext: flowState.selectedServices.isEmpty
                ? null
                : () {
                    final treatmentServices = flowState.selectedServices
                        .where((s) => s.hasTreatments)
                        .toList();
                    if (treatmentServices.isNotEmpty) {
                      context.push(
                          '/order/treatment/${treatmentServices.first.id}/types');
                    } else {
                      context.push('/order/garments');
                    }
                  },
          ),
        ],
      ),
    );
  }
}

// ─── Grouping logic — produces section headers + 2-column grid rows ──────────

abstract class _ListItem {}

class _SectionHeaderData extends _ListItem {
  final String title;
  _SectionHeaderData(this.title);
}

class _ServiceGridRow extends _ListItem {
  final List<ServiceModel> services; // 1 or 2 services per row
  _ServiceGridRow(this.services);
}

List<_ListItem> _groupServices(List<ServiceModel> services, String category) {
  final items = <_ListItem>[];

  void addServicesAsGrid(String title, List<ServiceModel> svcList) {
    if (svcList.isEmpty) return;
    items.add(_SectionHeaderData(title));
    for (var i = 0; i < svcList.length; i += 2) {
      final row = svcList.sublist(i, (i + 2).clamp(0, svcList.length));
      items.add(_ServiceGridRow(row));
    }
  }

  if (category == 'All') {
    final clothes =
        services.where((s) => s.category == 'clothes').toList();
    final homeLinen =
        services.where((s) => s.category == 'home_linen').toList();
    final specialty =
        services.where((s) => s.category == 'specialty').toList();

    addServicesAsGrid('CLOTHES', clothes);
    addServicesAsGrid('HOME LINEN', homeLinen);
    addServicesAsGrid('SPECIALTY', specialty);
  } else {
    final catKey = {
      'Clothes': 'clothes',
      'Home linen': 'home_linen',
      'Specialty': 'specialty',
    }[category];
    final filtered = services.where((s) => s.category == catKey).toList();
    for (var i = 0; i < filtered.length; i += 2) {
      final row = filtered.sublist(i, (i + 2).clamp(0, filtered.length));
      items.add(_ServiceGridRow(row));
    }
  }
  return items;
}

// ─── Services provider ──────────────────────────────────────────────────────

final _servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final repo = ref.watch(servicesRepositoryProvider);
  final result = await repo.getServices();
  List<ServiceModel> services;
  if (result.success && result.data != null && result.data!.isNotEmpty) {
    services = result.data!;
  } else {
    services = kFallbackServices;
  }
  ref.read(createOrderFlowProvider.notifier).validateCachedServices(services);
  return services;
});

// ─── Service grid card — matching mockup svc-card style ─────────────────────

class _ServiceGridCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceGridCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = service.emoji ?? '\u{1F455}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Check indicator at top right
            if (isSelected)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white),
                ),
              ),
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            // Name
            Text(
              service.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Price
            Text(
              'from \u{20B9}${service.pricePerPiece.toStringAsFixed(0)}/${_unitShort(service)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _unitShort(ServiceModel s) {
    final n = s.name.toLowerCase();
    if (n.contains('shoe')) return 'pr';
    if (n.contains('bed') || n.contains('pillow')) return 'set';
    if (n.contains('curtain')) return 'panel';
    return 'pc';
  }
}

// ─── Bottom bar ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onNext;

  const _BottomBar({required this.selectedCount, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount service${selectedCount == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 12, color: AppColors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Can combine multiple',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: onNext != null
                      ? const LinearGradient(
                          colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                        )
                      : null,
                  color: onNext == null ? AppColors.textHint : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: onNext != null
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Add Items \u{2192}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onNext != null
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

class _ServicesShimmer extends StatelessWidget {
  const _ServicesShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
