import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/core/network/dio_client.dart';
import 'package:presso_operations/features/admin/domain/models/service_zone_model.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // ── Service Zones ──────────────────────────────────────────────────────────

  Future<List<ServiceZoneModel>> getServiceZones({bool? isActive}) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams['isActive'] = isActive;

    final response = await _dio.get(
      '/api/admin/service-zones',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => ServiceZoneModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceZoneModel> getServiceZone(String id) async {
    final response = await _dio.get('/api/admin/service-zones/$id');
    return ServiceZoneModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceZoneModel> createServiceZone(
      Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/admin/service-zones',
      data: data,
    );
    return ServiceZoneModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceZoneModel> updateServiceZone(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      '/api/admin/service-zones/$id',
      data: data,
    );
    return ServiceZoneModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteServiceZone(String id) async {
    await _dio.delete('/api/admin/service-zones/$id');
  }

  Future<int> bulkToggleZones(List<String> zoneIds, bool isActive) async {
    final response = await _dio.post(
      '/api/admin/service-zones/bulk-toggle',
      data: {
        'zoneIds': zoneIds,
        'isActive': isActive,
      },
    );
    return response.data['data'] as int;
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});
