import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/referral_model.dart';

class ReferralRepository {
  final Dio _dio;

  ReferralRepository(this._dio);

  Future<ApiResponse<ReferralStats>> getMyCode() async {
    try {
      final response = await _dio.get(ApiConstants.referralCode);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final statsData = data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse(
          success: true,
          data: ReferralStats.fromJson(statsData),
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load referral code',
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

  Future<ApiResponse<String>> applyCode(String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.referralApply,
        data: {'code': code},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final message =
            data['message'] as String? ?? 'Referral code applied successfully';
        return ApiResponse(success: true, data: message);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to apply referral code',
      );
    } on DioException catch (e) {
      final errData = e.response?.data;
      final errMsg = errData is Map ? errData['message'] as String? : null;
      return ApiResponse(
        success: false,
        message: errMsg ?? e.message ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<ReferralHistory>>> getHistory() async {
    try {
      final response = await _dio.get(ApiConstants.referralHistory);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> rawList =
            data['data'] as List<dynamic>? ??
            data['history'] as List<dynamic>? ??
            [];

        final history = rawList
            .whereType<Map<String, dynamic>>()
            .map(ReferralHistory.fromJson)
            .toList();

        return ApiResponse(success: true, data: history);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load referral history',
        data: [],
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Network error',
        data: [],
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e', data: []);
    }
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReferralRepository(dio);
});
