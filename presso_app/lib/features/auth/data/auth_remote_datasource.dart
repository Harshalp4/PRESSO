import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/core/constants/api_constants.dart';
import 'package:presso_app/core/network/dio_client.dart';
import 'package:presso_app/features/auth/domain/models/user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  /// POST /api/auth/login
  /// Authenticates with Firebase ID token, returns JWT + user.
  Future<AuthResponse> loginWithFirebase(
    String firebaseIdToken, {
    String? fcmToken,
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'firebaseToken': firebaseIdToken,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };

    final response = await _dio.post(
      ApiConstants.login,
      data: body,
    );

    final raw = response.data as Map<String, dynamic>;
    final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
    return AuthResponse.fromJson(payload);
  }

  /// POST /api/auth/refresh
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );

    final raw = response.data as Map<String, dynamic>;
    final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
    return AuthResponse.fromJson(payload);
  }

  /// GET /api/users/me
  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.me);
    final raw = response.data as Map<String, dynamic>;
    final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
    return UserModel.fromJson(payload);
  }

  /// PUT /api/users/me
  Future<UserModel> updateProfile({
    String? name,
    String? email,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };

    final response = await _dio.put(
      ApiConstants.me,
      data: body,
    );

    final raw = response.data as Map<String, dynamic>;
    final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
    return UserModel.fromJson(payload);
  }

  /// PATCH /api/users/me/fcm-token
  Future<void> updateFcmToken(String token) async {
    await _dio.patch(
      ApiConstants.fcmToken,
      data: {'fcmToken': token},
    );
  }
}

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDatasource(dio);
});
