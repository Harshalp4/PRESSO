import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_operations/core/network/dio_client.dart';
import 'package:presso_operations/features/rider/domain/models/earnings_model.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';

class RiderRepository {
  final Dio _dio;

  RiderRepository(this._dio);

  Future<RiderJobsResponse> getJobs({String? date, String? search}) async {
    final qp = <String, dynamic>{};
    if (date != null && date.isNotEmpty) qp['date'] = date;
    if (search != null && search.isNotEmpty) qp['search'] = search;
    final response = await _dio.get(
      '/api/riders/me/jobs',
      queryParameters: qp.isEmpty ? null : qp,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return RiderJobsResponse.fromJson(data);
  }

  /// Completed assignments for the rider history tab.
  /// Backed by GET /api/riders/me/jobs/history.
  Future<RiderJobsResponse> getJobHistory({
    int limit = 50,
    int offset = 0,
    String? type, // "Pickup" | "Delivery"
  }) async {
    final response = await _dio.get(
      '/api/riders/me/jobs/history',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        if (type != null) 'type': type,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return RiderJobsResponse.fromJson(data);
  }

  Future<AssignmentModel> getJobDetail(String assignmentId) async {
    final response = await _dio.get('/api/riders/me/job/$assignmentId');
    final data = response.data['data'] as Map<String, dynamic>;
    final assignment = data['assignment'] as Map<String, dynamic>;
    return AssignmentModel.fromJson(assignment);
  }

  Future<void> updateAvailability(bool isAvailable) async {
    await _dio.patch(
      '/api/riders/me/availability',
      data: {'isAvailable': isAvailable},
    );
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _dio.patch(
      '/api/riders/me/location',
      data: {'latitude': lat, 'longitude': lng},
    );
  }

  Future<void> markArrived(String assignmentId) async {
    await _dio.patch('/api/riders/me/job/$assignmentId/arrived');
  }

  Future<List<String>> uploadPhotos(
      String assignmentId, List<File> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }
    final response = await _dio.post(
      '/api/riders/me/job/$assignmentId/photos',
      data: formData,
    );
    final data = response.data['data'];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> confirmPickup({
    required String assignmentId,
    required String otp,
    required int count,
    String? notes,
  }) async {
    await _dio.patch(
      '/api/riders/me/job/$assignmentId/confirm-pickup',
      data: {
        'otp': otp,
        'count': count,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> confirmDelivery({
    required String assignmentId,
    required String otp,
    String? notes,
  }) async {
    await _dio.patch(
      '/api/riders/me/job/$assignmentId/confirm-delivery',
      data: {
        'otp': otp,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> uploadShoePhotos(
      String assignmentId, String shoeItemId, List<File> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'photos',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }
    await _dio.post(
      '/api/riders/me/job/$assignmentId/shoe-photos',
      data: formData,
      queryParameters: {'shoeItemId': shoeItemId},
    );
  }

  Future<Map<String, dynamic>> acceptJob(String orderId) async {
    final response = await _dio.post('/api/riders/me/jobs/$orderId/accept');
    return response.data['data'] as Map<String, dynamic>;
  }

  // ===== Offer flow (wireframe screens 5/6/15) =====

  /// GET /api/riders/me/current-offer — returns the rider's active offered
  /// assignment, or null if there is none.
  Future<AssignmentModel?> getCurrentOffer() async {
    final response = await _dio.get('/api/riders/me/current-offer');
    final data = response.data['data'];
    if (data == null) return null;
    final assignment = data['assignment'];
    if (assignment == null) return null;
    return AssignmentModel.fromJson(assignment as Map<String, dynamic>);
  }

  /// POST /api/riders/me/job/{assignmentId}/accept
  /// On success returns the accepted assignment id. On 409 the server returns
  /// a code (`offer_not_available` / `offer_expired` / `offer_lost`) that the
  /// caller surfaces as the "Job Locked" screen.
  Future<String> acceptAssignment(String assignmentId) async {
    final response =
        await _dio.post('/api/riders/me/job/$assignmentId/accept');
    final data = response.data['data'] as Map<String, dynamic>;
    return data['assignmentId'] as String;
  }

  /// POST /api/riders/me/job/{assignmentId}/decline
  Future<void> declineAssignment(String assignmentId) async {
    await _dio.post('/api/riders/me/job/$assignmentId/decline');
  }

  /// POST /api/riders/me/job/{assignmentId}/start-drop
  /// Rider-side half of the two-sided drop-off handshake. Backend generates
  /// (or reuses) a 4-digit OTP with a 5-minute TTL that the rider shows to
  /// facility staff; staff enters it in the facility app to confirm receipt.
  Future<DropOtpModel> startDrop(String assignmentId) async {
    final response =
        await _dio.post('/api/riders/me/job/$assignmentId/start-drop');
    final data = response.data['data'] as Map<String, dynamic>;
    return DropOtpModel.fromJson(data);
  }

  /// GET /api/facility/nearest?lat&lng — returns the nearest active facility
  /// store, used to render the "Drop at facility" screen card.
  Future<NearestFacilityModel> getNearestFacility({double? lat, double? lng}) async {
    final response = await _dio.get(
      '/api/facility/nearest',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return NearestFacilityModel.fromJson(data);
  }

  Future<EarningsResponse> getEarnings(String period) async {
    final response =
        await _dio.get('/api/riders/me/earnings', queryParameters: {
      'period': period,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return EarningsResponse.fromJson(data);
  }
}

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RiderRepository(dio);
});
