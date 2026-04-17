import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../domain/models/daily_message_model.dart';
import '../domain/models/home_data_model.dart';

class HomeRepository {
  final Dio _dio;

  HomeRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  Future<ApiResponse<DailyMessageModel>> getDailyMessage() async {
    try {
      final response = await _dio.get(ApiConstants.dailyMessage);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final messageData =
            data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse.success(DailyMessageModel.fromJson(messageData));
      }
      return ApiResponse.error(
        'Failed to fetch daily message',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<String>> getAiTip(BuildContext context) async {
    final hour = TimeOfDay.now().hour;
    String timeContext = 'morning';
    if (hour >= 12 && hour < 17) {
      timeContext = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeContext = 'evening';
    } else if (hour >= 21 || hour < 6) {
      timeContext = 'night';
    }
    return getRawAiTip(timeContext);
  }

  Future<ApiResponse<String>> getRawAiTip(String timeContext) async {
    try {
      final response = await _dio.get(
        ApiConstants.aiTip,
        queryParameters: {'timeContext': timeContext},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tip = data['tip'] as String? ??
            data['message'] as String? ??
            (data['data'] as Map<String, dynamic>?)?['tip'] as String? ??
            '';
        return ApiResponse.success(tip);
      }
      return ApiResponse.error(
        'Failed to fetch AI tip',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<ActiveOrderSummary>> getActiveOrders() async {
    try {
      final response = await _dio.get(
        ApiConstants.orders,
        queryParameters: {'status': 'active', 'limit': 1},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> ordersList =
            data['data'] as List<dynamic>? ??
                data['orders'] as List<dynamic>? ??
                [];

        if (ordersList.isNotEmpty) {
          final orderJson = ordersList.first as Map<String, dynamic>;
          return ApiResponse.success(ActiveOrderSummary.fromJson(orderJson));
        }
        return ApiResponse.success(
          ActiveOrderSummary(
            orderId: '',
            orderNumber: '',
            status: 'none',
            statusLabel: 'No active orders',
          ),
        );
      }
      return ApiResponse.error(
        'Failed to fetch active orders',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserSavings() async {
    try {
      final response = await _dio.get(ApiConstants.savings);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final savingsData =
            data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse.success(savingsData);
      }
      return ApiResponse.error(
        'Failed to fetch savings',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<int>> getCoinBalance() async {
    try {
      final response = await _dio.get(ApiConstants.coinsBalance);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final balance = data['balance'] as int? ??
            (data['data'] as Map<String, dynamic>?)?['balance'] as int? ??
            0;
        return ApiResponse.success(balance);
      }
      return ApiResponse.error(
        'Failed to fetch coin balance',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getServices() async {
    try {
      final response = await _dio.get(ApiConstants.services);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> list =
            data['data'] as List<dynamic>? ??
                data['services'] as List<dynamic>? ??
                [];
        final services = list
            .whereType<Map<String, dynamic>>()
            .toList();
        return ApiResponse.success(services);
      }
      return ApiResponse.error(
        'Failed to fetch services',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
}
