import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';
import 'token_storage.dart';

/// Interceptor responsible for:
/// 1. Attaching the Bearer JWT to every outgoing request.
/// 2. Attempting a token refresh when a 401 is received.
/// 3. Clearing stored credentials and redirecting to login when refresh fails.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _storage;

  /// Whether a refresh is currently in progress (prevents concurrent refreshes).
  bool _isRefreshing = false;

  AuthInterceptor(this._dio) : _storage = tokenStorage;

  // -------------------------------------------------------------------------
  // Request: attach token
  // -------------------------------------------------------------------------
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(kAccessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // -------------------------------------------------------------------------
  // Response: pass through
  // -------------------------------------------------------------------------
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  // -------------------------------------------------------------------------
  // Error: handle 401 with token refresh
  // -------------------------------------------------------------------------
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh for 401 responses
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Avoid infinite loops for the refresh endpoint itself
    if (err.requestOptions.path == ApiConstants.refresh) {
      await _clearTokens();
      return handler.next(err);
    }

    // Prevent concurrent refreshes
    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(kRefreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokens();
        return handler.next(err);
      }

      // Use a fresh Dio instance to avoid interceptor recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      final raw = response.data as Map<String, dynamic>;
      final payload = raw.containsKey('data') ? raw['data'] as Map<String, dynamic> : raw;
      final newAccessToken = payload['accessToken'] as String?;
      final newRefreshToken = payload['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _clearTokens();
        return handler.next(err);
      }

      // Persist new tokens
      await _storage.write(kAccessTokenKey, newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(kRefreshTokenKey, newRefreshToken);
      }

      // Retry the original request with the new access token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      await _clearTokens();
      return handler.next(err);
    } catch (_) {
      await _clearTokens();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Removes all stored credentials (called on logout or failed refresh).
  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(kAccessTokenKey),
      _storage.delete(kRefreshTokenKey),
     ]);
  }

  /// Public logout helper — clears tokens and can be called from auth logic.
  Future<void> clearTokens() => _clearTokens();
}
