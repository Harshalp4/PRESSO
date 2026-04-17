import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import 'api_interceptor.dart';
import 'token_storage.dart';

/// Creates and configures the singleton [Dio] instance used throughout the app.
Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  // Auth interceptor — reads JWT from secure storage and handles 401
  dio.interceptors.add(AuthInterceptor(dio));

  // Pretty logging — only in debug builds
  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  return dio;
}

/// Riverpod provider that exposes the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) => _createDio());

/// Storage key constants — shared with [AuthInterceptor].
const String kAccessTokenKey = 'access_token';
const String kRefreshTokenKey = 'refresh_token';

/// Global token storage instance.
final TokenStorage tokenStorage = TokenStorage();
