import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return AuthRepository(dioClient);
});

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<ApiResponse<Map<String, dynamic>>> login(
      String phone, String otp) async {
    try {
      dev.log('LOGIN: Attempting login to ${ApiConstants.baseUrl}${ApiConstants.login} with phone=$phone', name: 'AUTH');
      // Dummy OTP auth: any 4-digit OTP works.
      // API uses firebaseIdToken as the phone number in dev mode.
      final response = await _dioClient.post(
        ApiConstants.login,
        data: {
          'firebaseToken': phone,
        },
      );
      dev.log('LOGIN: Response received: ${response.statusCode} ${response.data}', name: 'AUTH');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final token = apiResponse.data!['accessToken'] as String? ?? apiResponse.data!['token'] as String?;
        if (token != null) {
          await saveToken(token);
        }
      }

      return apiResponse;
    } on DioException catch (e) {
      dev.log('LOGIN ERROR: type=${e.type} message=${e.message} statusCode=${e.response?.statusCode} error=${e.error}', name: 'AUTH');
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] as String? ?? 'Login failed',
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
      );
    } catch (e, st) {
      dev.log('LOGIN UNEXPECTED ERROR: $e\n$st', name: 'AUTH');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMe() async {
    try {
      final response = await _dioClient.get(ApiConstants.usersMe);

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] as String? ?? 'Failed to get user',
        );
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _getErrorMessage(e),
      );
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.jwtTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.jwtTokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.jwtTokenKey);
  }

  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return e.message ?? 'Something went wrong';
    }
  }
}
