import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/core/network/dio_client.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_model.dart';
import 'package:presso_operations/features/facility/domain/models/facility_order_detail_model.dart';
import 'package:presso_operations/features/facility/domain/models/facility_stats_model.dart';

class FacilityRepository {
  final Dio _dio;

  FacilityRepository(this._dio);

  Future<List<FacilityOrderModel>> getOrders({
    String? storeId,
    String? date,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (storeId != null) queryParams['storeId'] = storeId;
    if (date != null) queryParams['date'] = date;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/api/facility/orders',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => FacilityOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacilityOrderDetailModel> getOrderDetail(String orderId) async {
    final response = await _dio.get('/api/facility/orders/$orderId');
    return FacilityOrderDetailModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> updateStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    await _dio.patch(
      '/api/facility/orders/$orderId/status',
      data: body,
    );
  }

  Future<void> updateShoeStatus(
    String orderId,
    String shoeItemId,
    String status, {
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'shoeItemId': shoeItemId,
      'status': status,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    await _dio.patch(
      '/api/facility/orders/$orderId/shoe-status',
      data: body,
    );
  }

  Future<FacilityOrderDetailModel> scanOrder(String orderNumber) async {
    final response = await _dio.post(
      '/api/facility/orders/scan',
      data: {'orderNumber': orderNumber},
    );
    return FacilityOrderDetailModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<FacilityStatsModel> getStats() async {
    final response = await _dio.get('/api/facility/stats');
    return FacilityStatsModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // ===== Dispatch flow (wireframe screen 14) =====

  /// GET /api/facility/orders/{id}/suggested-rider — returns the nearest
  /// available rider, or null if none are online.
  Future<SuggestedRiderModel?> getSuggestedRider(String orderId) async {
    try {
      final response =
          await _dio.get('/api/facility/orders/$orderId/suggested-rider');
      final data = response.data['data'];
      if (data == null) return null;
      return SuggestedRiderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/facility/orders/{id}/dispatch — creates a 60s Offered Delivery
  /// assignment for the rider. Returns the new assignmentId on success.
  Future<DispatchResultModel> dispatchOrder(String orderId, String riderId) async {
    final response = await _dio.post(
      '/api/facility/orders/$orderId/dispatch',
      data: {'riderId': riderId},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return DispatchResultModel.fromJson(data);
  }

  // ===== Drop-off handshake (two-sided OTP with the rider) =====

  /// POST /api/facility/drop/verify — facility-side half of the drop-off
  /// handshake. Staff types the 4-digit code the rider is showing on their
  /// phone. On success the backend flips the assignment to
  /// ReceivedAtFacility and returns the updated order detail.
  Future<FacilityOrderDetailModel> verifyDrop(String otp) async {
    final response = await _dio.post(
      '/api/facility/drop/verify',
      data: {'otp': otp},
    );
    return FacilityOrderDetailModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}

class SuggestedRiderModel {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final double? distanceKm;
  final bool isOnline;

  SuggestedRiderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.distanceKm,
    required this.isOnline,
  });

  factory SuggestedRiderModel.fromJson(Map<String, dynamic> json) =>
      SuggestedRiderModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Rider',
        phone: json['phone'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        isOnline: json['isOnline'] as bool? ?? false,
      );
}

class DispatchResultModel {
  final String assignmentId;
  final String riderId;
  final DateTime? offerExpiresAt;
  final int secondsRemaining;

  DispatchResultModel({
    required this.assignmentId,
    required this.riderId,
    this.offerExpiresAt,
    required this.secondsRemaining,
  });

  factory DispatchResultModel.fromJson(Map<String, dynamic> json) =>
      DispatchResultModel(
        assignmentId: json['assignmentId'] as String? ?? '',
        riderId: json['riderId'] as String? ?? '',
        offerExpiresAt: json['offerExpiresAt'] != null
            ? DateTime.tryParse(json['offerExpiresAt'] as String)
            : null,
        secondsRemaining: json['secondsRemaining'] as int? ?? 60,
      );
}

final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  return FacilityRepository(ref.watch(dioProvider));
});
