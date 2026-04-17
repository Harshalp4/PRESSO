// Facility dashboard — redesigned to match Presso_Mobile_Wireframes.html
// (Facility section: order queue, stats strip, quick-action cards).
//
// All data flow (facilityOrdersProvider, stats provider, SignalR) is
// preserved; only the visual layer has been rebuilt on the shared
// Presso UI kit so that the facility console matches the wireframe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presso_operations/core/constants/api_constants.dart';
import 'package:presso_operations/core/services/signalr_service.dart';
import 'package:presso_operations/core/widgets/presso_ui.dart';
import 'package:presso_operations/features/auth/presentation/providers/auth_provider.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_model.dart';
import 'package:presso_operations/features/facility/presentation/providers/facility_provider.dart';

class FacilityDashboardScreen extends ConsumerStatefulWidget {
  const FacilityDashboardScreen({super.key});

  @override
  ConsumerState<FacilityDashboardScreen> createState() =>
      _FacilityDashboardScreenState();
}

class _FacilityDashboardScreenState
    extends ConsumerState<FacilityDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.jwtTokenKey);
    if (token == null) return;
    final signalR = ref.read(signalRServiceProvider);
    await signalR.connect(token);
    signalR.onNotification(_onSignalRNotification);
  }

  void _onSignalRNotification(Map<String, dynamic> notification) {
    ref.read(facilityOrdersProvider.notifier).loadOrders();
    ref.invalidate(facilityStatsProvider);
    if (!mounted) return;
    final title = notification['title'] as String? ??
        notification['Title'] as String? ??
        'New notification';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        backgroundColor: PressoTokens.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    ref.read(signalRServiceProvider).removeListener(_onSignalRNotification);
    super.dispose();
  }

  // ── Status mapping ────────────────────────────────────────────────────────
  PressoChipColor _statusChipColor(String status) {
    switch (status) {
      case 'AtFacility':
        return PressoChipColor.teal;
      case 'Washing':
        return PressoChipColor.blue;
      case 'Ironing':
        return PressoChipColor.amber;
      case 'Ready':
        return PressoChipColor.green;
      case 'PickedUp':
        return PressoChipColor.purple;
      case 'OutForDelivery':
        return PressoChipColor.purple;
      case 'Delivered':
        return PressoChipColor.green;
      default:
        return PressoChipColor.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'AtFacility':
        return 'AT FACILITY';
      case 'Washing':
        return 'WASHING';
      case 'Ironing':
        return 'IRONING';
      case 'Ready':
        return 'READY';
      case 'PickedUp':
        return 'PICKED UP';
      case 'OutForDelivery':
        return 'OUT FOR DELIVERY';
      case 'Delivered':
        return 'DELIVERED';
      default:
        return status.toUpperCase();
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

  String _quickActionLabel(String status) {
    switch (status) {
      case 'AtFacility':
        return 'Start Washing';
      case 'Washing':
        return 'Move to Ironing';
      case 'Ironing':
        return 'Mark Ready';
      default:
        return '';
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _serviceIcon(String s) {
    final l = s.toLowerCase();
    if (l.contains('wash')) return Icons.local_laundry_service;
    if (l.contains('iron') || l.contains('press')) return Icons.iron;
    if (l.contains('dry')) return Icons.dry_cleaning;
    if (l.contains('shoe')) return Icons.shopping_bag;
    return Icons.checkroom;
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(facilityOrdersProvider);
    final statsAsync = ref.watch(facilityStatsProvider);

    return Scaffold(
      backgroundColor: PressoTokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.factory_outlined,
                color: PressoTokens.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Facility Console',
              style: TextStyle(
                color: PressoTokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Scan lives in the bottom nav — no need for a duplicate in the
          // appbar, which pushed on top of the Orders branch and confused the
          // tab state.
          IconButton(
            icon: const Icon(Icons.logout,
                color: PressoTokens.red, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      body: PhoneColumn(
        child: RefreshIndicator(
          color: PressoTokens.primary,
          onRefresh: () async {
            await ref.read(facilityOrdersProvider.notifier).loadOrders();
            ref.invalidate(facilityStatsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            children: [
              statsAsync.when(
                data: (stats) => StatsRow(cards: [
                  StatCard(label: 'At Facility', value: '${stats.atFacility}'),
                  StatCard(
                    label: 'Washing',
                    value: '${stats.washing}',
                    valueColor: PressoTokens.blue,
                  ),
                  StatCard(
                    label: 'Ironing',
                    value: '${stats.ironing}',
                    valueColor: PressoTokens.amber,
                  ),
                  StatCard(
                    label: 'Ready',
                    value: '${stats.ready}',
                    valueColor: PressoTokens.green,
                  ),
                ]),
                loading: () => const SizedBox(
                  height: 70,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: PressoTokens.primary),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              _statusTabs(ordersState),
              _dateFilter(ordersState),
              _searchField(),
              const SizedBox(height: 6),
              if (ordersState.isLoading && ordersState.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: PressoTokens.primary),
                  ),
                )
              else if (ordersState.error != null && ordersState.orders.isEmpty)
                _errorState(ordersState.error!)
              else
                ..._orderList(ordersState.orders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTabs(FacilityOrdersState state) {
    final isActive = state.statusFilter == 'active';
    Widget tab(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? PressoTokens.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color:
                    selected ? Colors.white : PressoTokens.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PressoTokens.border),
        ),
        child: Row(
          children: [
            tab('Active', isActive, () {
              ref
                  .read(facilityOrdersProvider.notifier)
                  .setStatusFilter('active');
            }),
            tab('Completed', !isActive, () {
              ref
                  .read(facilityOrdersProvider.notifier)
                  .setStatusFilter('completed');
            }),
          ],
        ),
      ),
    );
  }

  Widget _dateFilter(FacilityOrdersState state) {
    final hasFilter = state.dateFilter != null;
    final label = hasFilter
        ? DateFormat('d MMM').format(DateTime.parse(state.dateFilter!))
        : 'All dates';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasFilter
                    ? PressoTokens.primary.withValues(alpha: .1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasFilter
                      ? PressoTokens.primary.withValues(alpha: .4)
                      : PressoTokens.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: hasFilter
                        ? PressoTokens.primary
                        : PressoTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: hasFilter
                          ? PressoTokens.primary
                          : PressoTokens.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          hasFilter ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ref
                  .read(facilityOrdersProvider.notifier)
                  .setDateFilter(null),
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: PressoTokens.border),
                ),
                child: const Icon(Icons.close,
                    size: 12, color: PressoTokens.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (picked != null) {
      ref
          .read(facilityOrdersProvider.notifier)
          .setDateFilter(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Widget _searchField() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PressoTokens.border),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              fontSize: 13,
              color: PressoTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search order number or customer…',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: PressoTokens.textHint,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: PressoTokens.textSecondary, size: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 16, color: PressoTokens.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
      );

  List<Widget> _orderList(List<FacilityOrderModel> orders) {
    var filtered = orders;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = orders
          .where((o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q))
          .toList();
    }
    filtered.sort((a, b) {
      final aT = a.statusUpdatedAt ?? DateTime.now();
      final bT = b.statusUpdatedAt ?? DateTime.now();
      return aT.compareTo(bT);
    });
    if (filtered.isEmpty) return [_emptyState()];
    return [
      const SizedBox(height: 10),
      ...filtered.map(_orderCard),
    ];
  }

  Widget _emptyState() {
    final isActive =
        ref.read(facilityOrdersProvider).statusFilter == 'active';
    final message = isActive
        ? 'No active orders at facility'
        : 'No completed orders yet';
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 60,
              color: PressoTokens.textHint.withValues(alpha: .6),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: PressoTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: PressoTokens.red, size: 44),
              const SizedBox(height: 10),
              const Text(
                'Failed to load orders',
                style: TextStyle(
                  fontSize: 13,
                  color: PressoTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg,
                style: const TextStyle(
                  fontSize: 11,
                  color: PressoTokens.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              BtnPrimary(
                label: 'Retry',
                onPressed: () =>
                    ref.read(facilityOrdersProvider.notifier).loadOrders(),
              ),
            ],
          ),
        ),
      );

  Widget _orderCard(FacilityOrderModel o) {
    final next = _nextStatus(o.status);

    return PressoCard(
      onTap: () => context.push('/facility/order/${o.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${o.orderNumber}',
                      style: const TextStyle(
                        color: PressoTokens.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.customerName,
                      style: const TextStyle(
                        color: PressoTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PressoChip(
                label: _statusLabel(o.status),
                color: _statusChipColor(o.status),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info row
          Row(
            children: [
              ...o.serviceNames.take(3).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(_serviceIcon(s),
                          size: 15, color: PressoTokens.textSecondary),
                    ),
                  ),
              const Spacer(),
              const Icon(Icons.checkroom,
                  size: 13, color: PressoTokens.textSecondary),
              const SizedBox(width: 3),
              Text(
                '${o.garmentCount}',
                style: const TextStyle(
                  fontSize: 11,
                  color: PressoTokens.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time,
                  size: 13, color: PressoTokens.textSecondary),
              const SizedBox(width: 3),
              Text(
                _timeAgo(o.statusUpdatedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: PressoTokens.textSecondary,
                ),
              ),
            ],
          ),

          // Special instructions
          if (o.specialInstructions != null &&
              o.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: PressoTokens.amber.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: PressoTokens.amber),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      o.specialInstructions!,
                      style: const TextStyle(
                        color: PressoTokens.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (o.isExpressDelivery) ...[
            const SizedBox(height: 6),
            const PressoChip(
              label: 'EXPRESS',
              color: PressoChipColor.red,
              icon: Icons.bolt,
            ),
          ],

          if (next != null) ...[
            const SizedBox(height: 6),
            BtnPrimary(
              label: _quickActionLabel(o.status),
              icon: Icons.arrow_forward,
              onPressed: () =>
                  context.push('/facility/order/${o.id}/status'),
            ),
          ],
        ],
      ),
    );
  }
}
