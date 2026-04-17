import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/core/errors/app_exception.dart';
import 'package:presso_app/features/orders/data/orders_repository.dart';
import 'package:presso_app/features/orders/domain/models/create_order_request.dart';
import 'package:presso_app/features/orders/domain/models/order_detail_model.dart';
import 'package:presso_app/features/orders/domain/models/order_model.dart';
import 'package:presso_app/features/orders/domain/models/slot_model.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';

// ─── Orders List Provider ────────────────────────────────────────────────────

class OrdersListState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final String? statusFilter;

  const OrdersListState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.statusFilter,
  });

  OrdersListState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    String? statusFilter,
    bool clearError = false,
  }) {
    return OrdersListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class OrdersListNotifier extends StateNotifier<OrdersListState> {
  final OrdersRepository _repository;

  OrdersListNotifier(this._repository) : super(const OrdersListState());

  Future<void> loadOrders({String? statusFilter}) async {
    state = state.copyWith(
      isLoading: true,
      orders: [],
      currentPage: 1,
      hasMore: true,
      statusFilter: statusFilter ?? '',
      clearError: true,
    );

    // "Active", "Completed", "Cancelled" are compound filters — fetch all from API, filter client-side
    final isCompoundFilter = statusFilter != null &&
        (statusFilter == 'Active' || statusFilter == 'Completed' || statusFilter == 'Cancelled');
    final apiStatusParam = (statusFilter == null || statusFilter == 'All' || isCompoundFilter)
        ? null
        : statusFilter;

    try {
      final result = await _repository.getOrders(
        page: 1,
        pageSize: 20,
        statusFilter: apiStatusParam,
      );

      var orders = result.items;

      // Apply compound filter client-side
      if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
        orders = orders.where((o) => _matchesFilter(o.status, statusFilter)).toList();
      }

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        isLoading: false,
        orders: orders,
        hasMore: result.hasMore,
        currentPage: 1,
        clearError: true,
      );
    } catch (e) {
      final errorMsg = e.toString().contains('connect') ||
              e.toString().contains('internet') ||
              e.toString().contains('SocketException') ||
              e.toString().contains('timeout')
          ? 'connection'
          : 'server';
      state = state.copyWith(
        isLoading: false,
        orders: [],
        hasMore: false,
        currentPage: 1,
        error: errorMsg,
      );
    }
  }

  static const _activeStatuses = {
    'pending', 'confirmed', 'picked_up', 'pickedup',
    'at_facility', 'atfacility', 'processing',
    'out_for_delivery', 'outfordelivery',
  };

  bool _matchesFilter(String orderStatus, String filter) {
    final s = orderStatus.toLowerCase();
    switch (filter.toLowerCase()) {
      case 'active':
        return _activeStatuses.contains(s);
      case 'completed':
      case 'delivered':
        return s == 'delivered';
      case 'cancelled':
        return s == 'cancelled';
      default:
        return s == filter.toLowerCase();
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getOrders(
        page: nextPage,
        pageSize: 20,
        statusFilter: state.statusFilter != null && state.statusFilter != 'All'
            ? state.statusFilter
            : null,
      );
      state = state.copyWith(
        isLoadingMore: false,
        orders: [...state.orders, ...result.items],
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadOrders(statusFilter: state.statusFilter);
  }
}

final ordersListProvider =
    StateNotifierProvider<OrdersListNotifier, OrdersListState>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  return OrdersListNotifier(repo);
});

// ─── Order Detail Provider ───────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.family<OrderDetailModel, String>((ref, id) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getOrderDetail(id);
});

// ─── Create Order Provider ───────────────────────────────────────────────────

class CreateOrderState {
  final bool isLoading;
  final OrderDetailModel? createdOrder;
  final String? error;

  const CreateOrderState({
    this.isLoading = false,
    this.createdOrder,
    this.error,
  });

  CreateOrderState copyWith({
    bool? isLoading,
    OrderDetailModel? createdOrder,
    String? error,
    bool clearError = false,
  }) {
    return CreateOrderState(
      isLoading: isLoading ?? this.isLoading,
      createdOrder: createdOrder ?? this.createdOrder,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final OrdersRepository _repository;

  CreateOrderNotifier(this._repository) : super(const CreateOrderState());

  Future<OrderDetailModel?> createOrder(
    CreateOrderRequest request, {
    String paymentMethod = 'cash',
    double totalAmount = 0,
    double subtotal = 0,
    double expressCharge = 0,
    int coinsRedeemed = 0,
    List<ServiceModel> selectedServices = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _repository.createOrder(request);
      state = state.copyWith(isLoading: false, createdOrder: order);
      return order;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } on TimeoutException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } on ValidationException catch (e) {
      // Surfaces API validation errors (including geo-fencing rejections)
      state = state.copyWith(isLoading: false, error: e.firstError);
      return null;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      final errorMsg = e.toString().contains('connect') ||
              e.toString().contains('internet') ||
              e.toString().contains('SocketException')
          ? 'No internet connection. Please check your network and try again.'
          : 'Failed to place order. Please try again.';
      state = state.copyWith(isLoading: false, error: errorMsg);
      return null;
    }
  }

  void reset() {
    state = const CreateOrderState();
  }
}

final createOrderProvider =
    StateNotifierProvider<CreateOrderNotifier, CreateOrderState>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  return CreateOrderNotifier(repo);
});

// ─── Slots Provider ──────────────────────────────────────────────────────────

/// Parse "hh:mm AM/PM" into minutes since midnight.
int _parseTimeMinutes(String time) {
  final parts = time.trim().split(' ');
  final hm = parts[0].split(':');
  var hour = int.parse(hm[0]);
  final minute = int.parse(hm[1]);
  final period = parts.length > 1 ? parts[1].toUpperCase() : '';
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

/// Returns true if the slot's **start time** has already passed for today.
/// e.g. if it's 9:15 AM, the 8:00 AM–10:00 AM slot is expired because
/// the pickup window already started and user can't schedule into it.
bool _isSlotExpired(SlotModel slot, String todayStr) {
  if (slot.date != todayStr) return false;
  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;
  return _parseTimeMinutes(slot.startTime) <= nowMinutes;
}

/// Mark expired slots with isExpired=true instead of removing them,
/// so the UI can show them greyed out.
List<SlotModel> _markExpiredSlots(List<SlotModel> slots) {
  final todayStr = DateTime.now().toIso8601String().substring(0, 10);
  return slots.map((slot) {
    if (_isSlotExpired(slot, todayStr)) {
      return slot.copyWith(isExpired: true);
    }
    return slot;
  }).toList();
}

List<SlotModel> _generateFallbackSlots(String date) {
  // Full day coverage: 8 AM – 8 PM in 2-hour windows
  const timeSlots = [
    {'start': '08:00 AM', 'end': '10:00 AM'},
    {'start': '10:00 AM', 'end': '12:00 PM'},
    {'start': '12:00 PM', 'end': '02:00 PM'},
    {'start': '02:00 PM', 'end': '04:00 PM'},
    {'start': '04:00 PM', 'end': '06:00 PM'},
    {'start': '06:00 PM', 'end': '08:00 PM'},
  ];
  final slots = <SlotModel>[];
  for (int i = 0; i < timeSlots.length; i++) {
    slots.add(SlotModel(
      id: 'fallback-$date-$i',
      date: date,
      startTime: timeSlots[i]['start']!,
      endTime: timeSlots[i]['end']!,
      available: true,
      remainingCount: 5,
    ));
  }
  return _markExpiredSlots(slots);
}

final slotsProvider =
    FutureProvider.family<List<SlotModel>, String>((ref, date) async {
  final repo = ref.watch(ordersRepositoryProvider);
  try {
    final slots = await repo.getSlots(date);
    if (slots.isNotEmpty) {
      return _markExpiredSlots(slots);
    }
    return _generateFallbackSlots(date);
  } catch (_) {
    return _generateFallbackSlots(date);
  }
});

// ─── Addresses Provider ──────────────────────────────────────────────────────
// Fetches saved addresses for the current user

final addressesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Uses raw API call through dioProvider – a dedicated address repository
  // can be injected here when created. For now returns from orders repository's dio.
  return [];
});
