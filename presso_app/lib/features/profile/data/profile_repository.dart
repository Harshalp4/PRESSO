import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

// ── Address Model ──────────────────────────────────────────────────────────────

class AddressModel {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String pincode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.pincode,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      addressLine1: json['addressLine1'] as String? ??
          json['address1'] as String? ??
          '',
      addressLine2: json['addressLine2'] as String? ?? json['address2'] as String?,
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? json['zip'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        'city': city,
        'pincode': pincode,
        'isDefault': isDefault,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  AddressModel copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? pincode,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AddressModel(id: $id, label: $label, city: $city)';
}

// ── Notification Model ─────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? orderId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.orderId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      isRead: json['isRead'] as bool? ?? false,
      orderId: json['orderId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      orderId: orderId,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'NotificationModel(id: $id, title: $title, type: $type)';
}

// ── Repository ─────────────────────────────────────────────────────────────────

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  // ── Addresses ──

  Future<ApiResponse<List<AddressModel>>> getAddresses() async {
    try {
      final response = await _dio.get(ApiConstants.addresses);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> rawList =
            data['data'] as List<dynamic>? ??
            data['addresses'] as List<dynamic>? ??
            [];

        final addresses = rawList
            .whereType<Map<String, dynamic>>()
            .map(AddressModel.fromJson)
            .toList();

        return ApiResponse(success: true, data: addresses);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load addresses',
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

  Future<ApiResponse<AddressModel>> createAddress(
      Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.addresses, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final addrData = data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse(
          success: true,
          data: AddressModel.fromJson(addrData),
        );
      }

      return ApiResponse(success: false, message: 'Failed to create address');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<AddressModel>> updateAddress(
      String id, Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.put('${ApiConstants.addresses}/$id', data: body);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final addrData = data['data'] as Map<String, dynamic>? ?? data;
        return ApiResponse(
          success: true,
          data: AddressModel.fromJson(addrData),
        );
      }

      return ApiResponse(success: false, message: 'Failed to update address');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<void>> deleteAddress(String id) async {
    try {
      final response = await _dio.delete('${ApiConstants.addresses}/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const ApiResponse(success: true);
      }

      return ApiResponse(success: false, message: 'Failed to delete address');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<void>> setDefaultAddress(String id) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.addresses}/$id/default',
      );

      if (response.statusCode == 200) {
        return const ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to set default address',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ── Notifications ──

  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> rawList =
            data['data'] as List<dynamic>? ??
            data['notifications'] as List<dynamic>? ??
            [];

        final notifications = rawList
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();

        return ApiResponse(success: true, data: notifications);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to load notifications',
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

  Future<ApiResponse<void>> markAsRead(String id) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.notifications}/$id/read',
      );

      if (response.statusCode == 200) {
        return const ApiResponse(success: true);
      }

      return ApiResponse(success: false, message: 'Failed to mark as read');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<void>> markAllRead() async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.notifications}/read-all',
      );

      if (response.statusCode == 200) {
        return const ApiResponse(success: true);
      }

      return ApiResponse(success: false, message: 'Failed to mark all as read');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: e.message ?? 'Network error');
    } catch (e) {
      return ApiResponse(success: false, message: 'Unexpected error: $e');
    }
  }

  // ── Service Zone Check ──

  /// Check if a pincode is serviceable.
  /// Returns (isServiceable, zoneName, message).
  Future<({bool isServiceable, String? zoneName, String? message})>
      checkPincodeServiceability(String pincode) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.serviceZoneCheck}/$pincode',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final payload = data['data'] as Map<String, dynamic>? ?? data;
        return (
          isServiceable: payload['isServiceable'] as bool? ?? false,
          zoneName: payload['zoneName'] as String?,
          message: payload['message'] as String?,
        );
      }

      return (isServiceable: true, zoneName: null, message: null);
    } catch (e) {
      // On error, don't block — let server-side validation handle it
      return (isServiceable: true, zoneName: null, message: null);
    }
  }

  // ── Student Verification ──

  Future<ApiResponse<String>> submitStudentVerification(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'college_id.jpg',
        ),
      });

      final response = await _dio.post(
        ApiConstants.studentVerify,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Submitted successfully';
        return ApiResponse(success: true, data: message);
      }

      return ApiResponse(
        success: false,
        message: 'Failed to submit verification',
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
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});
