import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/admin/domain/models/service_zone_model.dart';
import 'package:presso_operations/features/admin/presentation/providers/admin_provider.dart';

class ServiceZonesScreen extends ConsumerStatefulWidget {
  const ServiceZonesScreen({super.key});

  @override
  ConsumerState<ServiceZonesScreen> createState() =>
      _ServiceZonesScreenState();
}

class _ServiceZonesScreenState extends ConsumerState<ServiceZonesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zonesState = ref.watch(serviceZonesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Service Zones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
            onPressed: () => context.push('/admin/zones/create'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () =>
            ref.read(serviceZonesProvider.notifier).loadZones(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary strip
            _buildSummaryStrip(zonesState.zones),
            const SizedBox(height: 12),

            // Filter chips
            _buildFilterChips(zonesState),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name, pincode, or city...',
                hintStyle: TextStyle(color: AppColors.textHint),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),

            // List
            if (zonesState.isLoading && zonesState.zones.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (zonesState.error != null && zonesState.zones.isEmpty)
              _buildErrorState(zonesState.error!)
            else
              ..._buildZonesList(zonesState.zones),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/zones/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryStrip(List<ServiceZoneModel> zones) {
    final active = zones.where((z) => z.isActive).length;
    final inactive = zones.where((z) => !z.isActive).length;
    final cities =
        zones.map((z) => z.city).toSet().length;

    return Row(
      children: [
        _buildStatChip('Total', zones.length, AppColors.primary),
        const SizedBox(width: 8),
        _buildStatChip('Active', active, AppColors.green),
        const SizedBox(width: 8),
        _buildStatChip('Inactive', inactive, AppColors.red),
        const SizedBox(width: 8),
        _buildStatChip('Cities', cities, AppColors.purple),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ServiceZonesState state) {
    return Row(
      children: [
        _buildFilterChip('All', state.activeFilter == null, () {
          ref.read(serviceZonesProvider.notifier).setActiveFilter(null);
        }),
        const SizedBox(width: 8),
        _buildFilterChip('Active', state.activeFilter == true, () {
          ref.read(serviceZonesProvider.notifier).setActiveFilter(true);
        }),
        const SizedBox(width: 8),
        _buildFilterChip('Inactive', state.activeFilter == false, () {
          ref.read(serviceZonesProvider.notifier).setActiveFilter(false);
        }),
      ],
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildZonesList(List<ServiceZoneModel> zones) {
    var filtered = zones;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = zones
          .where((z) =>
              z.name.toLowerCase().contains(q) ||
              z.pincode.toLowerCase().contains(q) ||
              z.city.toLowerCase().contains(q) ||
              (z.area?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (filtered.isEmpty) {
      return [_buildEmptyState()];
    }

    return filtered.map((zone) => _buildZoneCard(zone)).toList();
  }

  Widget _buildZoneCard(ServiceZoneModel zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + status toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.pin_drop,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          zone.pincode,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_city,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            zone.city,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: zone.isActive,
                onChanged: (value) async {
                  final error = await ref
                      .read(serviceZonesProvider.notifier)
                      .toggleZone(zone.id, value);
                  if (error != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                },
                activeColor: AppColors.green,
                inactiveThumbColor: AppColors.textSecondary,
              ),
            ],
          ),

          // Area if present
          if (zone.area != null && zone.area!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.map, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  zone.area!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // Description if present
          if (zone.description != null &&
              zone.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              zone.description!,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Store assignment
          if (zone.assignedStoreName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store,
                      size: 13, color: AppColors.purple),
                  const SizedBox(width: 4),
                  Text(
                    zone.assignedStoreName!,
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/admin/zones/edit/${zone.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(zone),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Deactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(
                        color: AppColors.red.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ServiceZoneModel zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Deactivate Zone',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Deactivate "${zone.name}" (${zone.pincode})? '
          'Customers in this area won\'t be able to place orders.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref
          .read(serviceZonesProvider.notifier)
          .deleteZone(zone.id);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.red,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${zone.name} deactivated'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_off,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No service zones configured',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first zone',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load zones',
              style:
                  TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(serviceZonesProvider.notifier).loadZones(),
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
