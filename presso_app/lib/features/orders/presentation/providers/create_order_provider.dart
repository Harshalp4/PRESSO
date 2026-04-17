import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presso_app/features/orders/domain/models/address_model.dart';
import 'package:presso_app/features/orders/domain/models/create_order_request.dart';
import 'package:presso_app/features/orders/domain/models/slot_model.dart';
import 'package:presso_app/features/services/domain/models/service_model.dart';

// ─── Persistence keys ─────────────────────────────────────────────────────────

const _kSelectedServices = 'order_draft_services';
const _kGarmentCounts = 'order_draft_garment_counts';
const _kViewMode = 'garment_view_mode';

// ─── View mode enum ───────────────────────────────────────────────────────────

enum GarmentViewMode { list, grid, compact }

// ─── State ───────────────────────────────────────────────────────────────────

class CreateOrderFlowState {
  final List<ServiceModel> selectedServices;
  // Key: "{serviceId}_{garmentTypeId}" → quantity
  final Map<String, int> garmentCounts;
  final SlotModel? selectedSlot;
  final AddressModel? selectedAddress;
  final int coinsToRedeem;
  final bool isExpressDelivery;
  final String? specialInstructions;
  final String? paymentMethod; // 'online' | 'cash'
  final GarmentViewMode viewMode;

  // ─── Treatment selections ──────────────────────────────────────────────
  // Key: "{serviceId}_{garmentTypeId}" → treatmentId
  final Map<String, String> treatmentSelections;

  const CreateOrderFlowState({
    this.selectedServices = const [],
    this.garmentCounts = const {},
    this.selectedSlot,
    this.selectedAddress,
    this.coinsToRedeem = 0,
    this.isExpressDelivery = false,
    this.specialInstructions,
    this.paymentMethod = 'online',
    this.viewMode = GarmentViewMode.list,
    this.treatmentSelections = const {},
  });

  CreateOrderFlowState copyWith({
    List<ServiceModel>? selectedServices,
    Map<String, int>? garmentCounts,
    SlotModel? selectedSlot,
    AddressModel? selectedAddress,
    int? coinsToRedeem,
    bool? isExpressDelivery,
    String? specialInstructions,
    String? paymentMethod,
    GarmentViewMode? viewMode,
    Map<String, String>? treatmentSelections,
    bool clearSlot = false,
    bool clearAddress = false,
  }) {
    return CreateOrderFlowState(
      selectedServices: selectedServices ?? this.selectedServices,
      garmentCounts: garmentCounts ?? this.garmentCounts,
      selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
      selectedAddress:
          clearAddress ? null : (selectedAddress ?? this.selectedAddress),
      coinsToRedeem: coinsToRedeem ?? this.coinsToRedeem,
      isExpressDelivery: isExpressDelivery ?? this.isExpressDelivery,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      viewMode: viewMode ?? this.viewMode,
      treatmentSelections: treatmentSelections ?? this.treatmentSelections,
    );
  }

  // ─── Computed values ──────────────────────────────────────────────────────

  int get totalItemCount {
    return garmentCounts.values.fold(0, (sum, count) => sum + count);
  }

  double get subtotal {
    double total = 0.0;
    for (final service in selectedServices) {
      for (final garment in service.garmentTypes) {
        final key = '${service.id}_${garment.id}';
        final count = garmentCounts[key] ?? 0;
        if (count > 0) {
          final price = garment.priceOverride ?? service.pricePerPiece;
          total += price * count;
        }
      }
    }
    return total;
  }

  /// Compute coin discount using the coin-to-rupee rate from AppConfig.
  /// Default: 0.1 (i.e. 10 coins = ₹1).
  double coinDiscountFor({double coinValueRupees = 0.1}) {
    return coinsToRedeem * coinValueRupees;
  }

  /// Kept for backward compat — uses default rate.
  double get coinDiscountAmount => coinDiscountFor();

  /// Express charge from AppConfig (default ₹30).
  double expressChargeFor({double expressCharge = 30.0}) {
    return isExpressDelivery ? expressCharge : 0.0;
  }

  double get expressDeliveryCharge => expressChargeFor();

  /// Total using config values. Screens should prefer [totalFor].
  double totalFor({double coinValueRupees = 0.1, double expressCharge = 30.0}) {
    return (subtotal - coinDiscountFor(coinValueRupees: coinValueRupees) +
            expressChargeFor(expressCharge: expressCharge))
        .clamp(0.0, double.infinity);
  }

  double get totalAmount => totalFor();

  bool get isReadyToOrder {
    final hasItems = totalItemCount > 0;
    return selectedServices.isNotEmpty &&
        hasItems &&
        selectedSlot != null &&
        selectedAddress != null;
  }

  bool get hasEnoughItems => totalItemCount >= 3;

  List<OrderItemRequest> get orderItems {
    final items = <OrderItemRequest>[];
    for (final service in selectedServices) {
      for (final garment in service.garmentTypes) {
        final key = '${service.id}_${garment.id}';
        final count = garmentCounts[key] ?? 0;
        if (count > 0) {
          items.add(OrderItemRequest(
            serviceId: service.id,
            garmentTypeId: garment.id,
            quantity: count,
            serviceTreatmentId: treatmentSelections[key],
          ));
        }
      }
    }
    return items;
  }
}

// ─── Notifier with persistence ──────────────────────────────────────────────

class CreateOrderFlowNotifier extends StateNotifier<CreateOrderFlowState> {
  CreateOrderFlowNotifier() : super(const CreateOrderFlowState()) {
    _loadFromDisk();
  }

  // ─── Persistence ────────────────────────────────────────────────────────

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore view mode
    final viewModeIndex = prefs.getInt(_kViewMode) ?? 0;
    final viewMode = GarmentViewMode.values[
        viewModeIndex.clamp(0, GarmentViewMode.values.length - 1)];

    // Restore selected services
    final servicesJson = prefs.getString(_kSelectedServices);
    List<ServiceModel> services = [];
    if (servicesJson != null) {
      try {
        final list = jsonDecode(servicesJson) as List<dynamic>;
        services = list
            .whereType<Map<String, dynamic>>()
            .map(ServiceModel.fromJson)
            .toList();
      } catch (_) {}
    }

    // Restore garment counts
    final countsJson = prefs.getString(_kGarmentCounts);
    Map<String, int> counts = {};
    if (countsJson != null) {
      try {
        final map = jsonDecode(countsJson) as Map<String, dynamic>;
        counts = map.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }

    state = state.copyWith(
      selectedServices: services,
      garmentCounts: counts,
      viewMode: viewMode,
    );
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    // Save services
    final servicesJson =
        jsonEncode(state.selectedServices.map((s) => s.toJson()).toList());
    await prefs.setString(_kSelectedServices, servicesJson);
    // Save garment counts (only non-zero)
    final nonZeroCounts = Map<String, int>.fromEntries(
        state.garmentCounts.entries.where((e) => e.value > 0));
    await prefs.setString(_kGarmentCounts, jsonEncode(nonZeroCounts));
  }

  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kViewMode, state.viewMode.index);
  }

  // ─── Cache validation ─────────────────────────────────────────────────

  /// Call this when fresh service data arrives from the API.
  /// Removes any cached selections whose IDs no longer exist in [freshServices].
  void validateCachedServices(List<ServiceModel> freshServices) {
    final freshIds = freshServices.map((s) => s.id).toSet();
    final staleServices = state.selectedServices
        .where((s) => !freshIds.contains(s.id))
        .toList();

    if (staleServices.isEmpty) return;

    debugPrint(
      '[OrderFlow] Clearing ${staleServices.length} stale cached service(s): '
      '${staleServices.map((s) => '${s.name} (${s.id})').join(', ')}',
    );

    // Replace cached ServiceModels with fresh versions (preserving selection)
    final updatedServices = <ServiceModel>[];
    final updatedCounts = Map<String, int>.from(state.garmentCounts);
    final updatedTreatments = Map<String, String>.from(state.treatmentSelections);

    for (final cached in state.selectedServices) {
      final fresh = freshServices.where((s) => s.id == cached.id).firstOrNull;
      if (fresh != null) {
        updatedServices.add(fresh);
      } else {
        // Stale — remove garment counts & treatments for this service
        for (final g in cached.garmentTypes) {
          final key = '${cached.id}_${g.id}';
          updatedCounts.remove(key);
          updatedTreatments.remove(key);
        }
      }
    }

    state = state.copyWith(
      selectedServices: updatedServices,
      garmentCounts: updatedCounts,
      treatmentSelections: updatedTreatments,
    );
    _saveToDisk();
  }

  // ─── View mode ──────────────────────────────────────────────────────────

  void setViewMode(GarmentViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _saveViewMode();
  }

  // ─── Service management ─────────────────────────────────────────────────

  void addService(ServiceModel service) {
    if (state.selectedServices.any((s) => s.id == service.id)) return;
    state = state.copyWith(
      selectedServices: [...state.selectedServices, service],
    );
    _saveToDisk();
  }

  void removeService(ServiceModel service) {
    final newServices =
        state.selectedServices.where((s) => s.id != service.id).toList();
    final newCounts = Map<String, int>.from(state.garmentCounts);
    for (final garment in service.garmentTypes) {
      newCounts.remove('${service.id}_${garment.id}');
    }
    state = state.copyWith(
      selectedServices: newServices,
      garmentCounts: newCounts,
    );
    _saveToDisk();
  }

  void toggleService(ServiceModel service) {
    if (state.selectedServices.any((s) => s.id == service.id)) {
      removeService(service);
    } else {
      addService(service);
    }
  }

  void setGarmentCount({
    required String serviceId,
    required String garmentTypeId,
    required int count,
  }) {
    final key = '${serviceId}_$garmentTypeId';
    final newCounts = Map<String, int>.from(state.garmentCounts);
    if (count <= 0) {
      newCounts.remove(key);
    } else {
      newCounts[key] = count;
    }
    state = state.copyWith(garmentCounts: newCounts);
    _saveToDisk();
  }

  void incrementGarment({
    required String serviceId,
    required String garmentTypeId,
  }) {
    final key = '${serviceId}_$garmentTypeId';
    final current = state.garmentCounts[key] ?? 0;
    setGarmentCount(
      serviceId: serviceId,
      garmentTypeId: garmentTypeId,
      count: current + 1,
    );
  }

  void decrementGarment({
    required String serviceId,
    required String garmentTypeId,
  }) {
    final key = '${serviceId}_$garmentTypeId';
    final current = state.garmentCounts[key] ?? 0;
    if (current <= 0) return;
    setGarmentCount(
      serviceId: serviceId,
      garmentTypeId: garmentTypeId,
      count: current - 1,
    );
  }

  void setSlot(SlotModel? slot) {
    state = slot == null
        ? state.copyWith(clearSlot: true)
        : state.copyWith(selectedSlot: slot);
  }

  void setAddress(AddressModel? address) {
    state = address == null
        ? state.copyWith(clearAddress: true)
        : state.copyWith(selectedAddress: address);
  }

  void toggleExpress() {
    state = state.copyWith(isExpressDelivery: !state.isExpressDelivery);
  }

  void setExpressDelivery(bool value) {
    state = state.copyWith(isExpressDelivery: value);
  }

  void setCoins(int coins) {
    state = state.copyWith(coinsToRedeem: coins.clamp(0, 9999));
  }

  void setSpecialInstructions(String? instructions) {
    state = state.copyWith(specialInstructions: instructions);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  // ─── Treatment management ──────────────────────────────────────────────

  void setTreatment({
    required String serviceId,
    required String garmentTypeId,
    required String? treatmentId,
  }) {
    final key = '${serviceId}_$garmentTypeId';
    final newSelections = Map<String, String>.from(state.treatmentSelections);
    if (treatmentId == null) {
      newSelections.remove(key);
    } else {
      newSelections[key] = treatmentId;
    }
    state = state.copyWith(treatmentSelections: newSelections);
  }

  CreateOrderRequest buildRequest() {
    if (state.selectedAddress == null) {
      throw StateError('No address selected');
    }
    if (state.selectedSlot == null) {
      throw StateError('No pickup slot selected');
    }
    return CreateOrderRequest(
      addressId: state.selectedAddress!.id,
      pickupSlotId: state.selectedSlot!.id,
      items: state.orderItems,
      isExpressDelivery: state.isExpressDelivery,
      specialInstructions: state.specialInstructions,
      coinsToRedeem: state.coinsToRedeem,
    );
  }

  void reset() {
    state = const CreateOrderFlowState();
    _saveToDisk();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final createOrderFlowProvider =
    StateNotifierProvider<CreateOrderFlowNotifier, CreateOrderFlowState>((ref) {
  return CreateOrderFlowNotifier();
});

// ─── Addresses from API ──────────────────────────────────────────────────────

class AddressesNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressesNotifier() : super(const AsyncValue.loading());

  Future<void> load(Future<List<AddressModel>> Function() fetcher) async {
    state = const AsyncValue.loading();
    try {
      final addresses = await fetcher();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final savedAddressesProvider = StateNotifierProvider<AddressesNotifier,
    AsyncValue<List<AddressModel>>>((ref) {
  return AddressesNotifier();
});
