import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/features/facility/data/facility_repository.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_model.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_detail_model.dart';
import 'package:presso_operations/features/facility/domain/models/facility_stats_model.dart';

class FacilityOrdersState {
  final List<FacilityOrderModel> orders;
  final bool isLoading;
  final String? error;
  final String? dateFilter; // null = all, "2026-03-19" = specific date
  // "active" = on the facility floor (PickedUp/InProcess/ReadyForDelivery).
  // "completed" = already handed to rider or delivered, for audit.
  final String statusFilter;

  FacilityOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.dateFilter,
    this.statusFilter = 'active',
  });

  FacilityOrdersState copyWith({
    List<FacilityOrderModel>? orders,
    bool? isLoading,
    String? error,
    String? dateFilter,
    bool clearDateFilter = false,
    String? statusFilter,
  }) {
    return FacilityOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class FacilityOrdersNotifier extends StateNotifier<FacilityOrdersState> {
  final FacilityRepository _repository;
  Timer? _refreshTimer;

  FacilityOrdersNotifier(this._repository)
      : super(FacilityOrdersState()) {
    loadOrders();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => loadOrders(),
    );
  }

  Future<void> loadOrders({String? storeId}) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _repository.getOrders(
        storeId: storeId,
        date: state.dateFilter,
        status: state.statusFilter,
      );
      if (!mounted) return;
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setDateFilter(String? date) async {
    if (date == state.dateFilter) return;
    state = state.copyWith(dateFilter: date, clearDateFilter: date == null);
    await loadOrders();
  }

  Future<void> setStatusFilter(String filter) async {
    if (filter == state.statusFilter) return;
    state = state.copyWith(statusFilter: filter, orders: const []);
    await loadOrders();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final facilityOrdersProvider =
    StateNotifierProvider<FacilityOrdersNotifier, FacilityOrdersState>((ref) {
  final repository = ref.watch(facilityRepositoryProvider);
  return FacilityOrdersNotifier(repository);
});

final facilityOrderDetailProvider =
    FutureProvider.family<FacilityOrderDetailModel, String>(
        (ref, orderId) async {
  final repository = ref.watch(facilityRepositoryProvider);
  return repository.getOrderDetail(orderId);
});

final facilityStatsProvider =
    FutureProvider<FacilityStatsModel>((ref) async {
  final repository = ref.watch(facilityRepositoryProvider);
  return repository.getStats();
});
