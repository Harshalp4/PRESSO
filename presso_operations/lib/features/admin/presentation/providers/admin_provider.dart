import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/features/admin/data/admin_repository.dart';
import 'package:presso_operations/features/admin/domain/models/service_zone_model.dart';

// ── State ────────────────────────────────────────────────────────────────────

class ServiceZonesState {
  final List<ServiceZoneModel> zones;
  final bool isLoading;
  final String? error;
  final bool? activeFilter; // null = all, true = active only, false = inactive

  ServiceZonesState({
    this.zones = const [],
    this.isLoading = false,
    this.error,
    this.activeFilter,
  });

  ServiceZonesState copyWith({
    List<ServiceZoneModel>? zones,
    bool? isLoading,
    String? error,
    bool? activeFilter,
    bool clearActiveFilter = false,
  }) {
    return ServiceZonesState(
      zones: zones ?? this.zones,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeFilter:
          clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ServiceZonesNotifier extends StateNotifier<ServiceZonesState> {
  final AdminRepository _repository;

  ServiceZonesNotifier(this._repository) : super(ServiceZonesState()) {
    loadZones();
  }

  Future<void> loadZones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final zones =
          await _repository.getServiceZones(isActive: state.activeFilter);
      state = state.copyWith(zones: zones, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setActiveFilter(bool? filter) async {
    state = state.copyWith(
        activeFilter: filter, clearActiveFilter: filter == null);
    await loadZones();
  }

  Future<String?> createZone(Map<String, dynamic> data) async {
    try {
      await _repository.createServiceZone(data);
      await loadZones();
      return null; // success
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> updateZone(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateServiceZone(id, data);
      await loadZones();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> toggleZone(String id, bool isActive) async {
    try {
      await _repository.updateServiceZone(id, {'isActive': isActive});
      await loadZones();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> deleteZone(String id) async {
    try {
      await _repository.deleteServiceZone(id);
      await loadZones();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> bulkToggle(List<String> ids, bool isActive) async {
    try {
      await _repository.bulkToggleZones(ids, isActive);
      await loadZones();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  String _extractError(dynamic e) {
    // Properly extract API error messages from DioException
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // ApiResponse wrapper: { "message": "...", "data": null }
        if (data['message'] is String) return data['message'] as String;
        // Nested errors: { "errors": { "field": ["msg"] } }
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final first = errors.values.firstOrNull;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      if (data is String && data.isNotEmpty) return data;
    }
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Request timed out. Please try again.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please check your network.';
      }
    }
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return e.toString();
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final serviceZonesProvider =
    StateNotifierProvider<ServiceZonesNotifier, ServiceZonesState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return ServiceZonesNotifier(repository);
});
