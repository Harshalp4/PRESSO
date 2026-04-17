import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/savings_model.dart';

class SavingsRepository {
  final Dio _dio;

  SavingsRepository(this._dio);

  Future<ApiResponse<SavingsModel>> getSavings() async {
    try {
      final response = await _dio.get(ApiConstants.savings);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final savingsData = data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse(
          success: true,
          data: SavingsModel.fromJson(savingsData),
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load savings',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<CoinBalance>> getCoinBalance() async {
    try {
      final response = await _dio.get(ApiConstants.coinsBalance);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final balanceData = data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse(
          success: true,
          data: CoinBalance.fromJson(balanceData),
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load coin balance',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<PaginatedResponse<LedgerEntry>>> getCoinHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.coinsHistory,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final paginated = PaginatedResponse.fromJson(
          data['data'] as Map<String, dynamic>? ?? data,
          LedgerEntry.fromJson,
        );
        return ApiResponse(success: true, data: paginated);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load coin history',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SavingsRepository(dio);
});
