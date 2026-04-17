import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/core/constants/api_constants.dart';
import 'package:presso_app/core/errors/app_exception.dart';
import 'package:presso_app/core/network/api_response.dart';
import 'package:presso_app/core/network/dio_client.dart';
import 'package:presso_app/features/orders/domain/models/create_order_request.dart';
import 'package:presso_app/features/orders/domain/models/order_detail_model.dart';
import 'package:presso_app/features/orders/domain/models/order_model.dart';
import 'package:presso_app/features/orders/domain/models/slot_model.dart';

class OrdersRepository {
  final Dio _dio;

  OrdersRepository(this._dio);

  /// GET /api/orders?page=1&pageSize=20
  Future<PaginatedResponse<OrderModel>> getOrders({
    int page = 1,
    int pageSize = 20,
    String? statusFilter,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'status': statusFilter,
      };

      final response = await _dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      // API returns { success, data: { items, totalCount, page, pageSize } }
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      return PaginatedResponse.fromJson(
        payload,
        OrderModel.fromJson,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/orders/:id
  Future<OrderDetailModel> getOrderDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.orders}/$id');
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      return OrderDetailModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/orders
  Future<OrderDetailModel> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.orders,
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      return OrderDetailModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/orders/:id/repeat
  Future<OrderDetailModel> repeatOrder({
    required String originalId,
    required String addressId,
    required String slotId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.orders}/$originalId/repeat',
        data: {
          'addressId': addressId,
          'pickupSlotId': slotId,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      return OrderDetailModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/slots?date=YYYY-MM-DD
  Future<List<SlotModel>> getSlots(String date) async {
    try {
      final response = await _dio.get(
        ApiConstants.slots,
        queryParameters: {'date': date},
      );
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>? ??
          data['slots'] as List<dynamic>? ??
          (data is List ? data as List<dynamic> : []);
      return rawList
          .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/orders/:id/confirm-pickup-otp
  Future<void> confirmPickupOtp({
    required String orderId,
    required String otp,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.orders}/$orderId/confirm-pickup-otp',
        data: {'otp': otp},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/orders/:id/confirm-delivery-otp
  Future<void> confirmDeliveryOtp({
    required String orderId,
    required String otp,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.orders}/$orderId/confirm-delivery-otp',
        data: {'otp': otp},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ??
          (data['errors'] as List?)?.firstOrNull?.toString() ??
          message;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(message: 'Request timed out. Please retry.');
      case DioExceptionType.connectionError:
        return NetworkException(
            message: 'No internet connection. Please check your network.');
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        } else if (statusCode == 404) {
          return NotFoundException(message: message);
        } else if (statusCode == 422 || statusCode == 400) {
          final errors = (data is Map ? data['errors'] as List? : null)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          return ValidationException(message: message, errors: errors);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message, statusCode: statusCode);
        }
        return AppException(message: message, statusCode: statusCode);
      default:
        return UnknownException(message: message);
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrdersRepository(dio);
});
