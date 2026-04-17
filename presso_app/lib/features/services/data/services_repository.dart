import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/service_model.dart';

class ServicesRepository {
  final Dio _dio;
  List<ServiceModel>? _cache;

  ServicesRepository(this._dio);

  Future<ApiResponse<List<ServiceModel>>> getServices({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) {
      return ApiResponse(success: true, data: _cache);
    }

    try {
      final response = await _dio.get(ApiConstants.services);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> rawList =
            data['data'] as List<dynamic>? ??
            data['services'] as List<dynamic>? ??
            [];

        final services = rawList
            .whereType<Map<String, dynamic>>()
            .map(ServiceModel.fromJson)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        _cache = services;
        return ApiResponse(success: true, data: services);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load services',
        data: [],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Network error',
        data: [],
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
      );
    }
  }

  void clearCache() => _cache = null;
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ServicesRepository(dio);
});
