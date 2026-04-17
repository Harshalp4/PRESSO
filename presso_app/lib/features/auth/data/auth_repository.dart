import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/core/network/token_storage.dart';
import 'package:presso_app/core/network/dio_client.dart';
import 'package:presso_app/features/auth/data/auth_remote_datasource.dart';
import 'package:presso_app/features/auth/domain/models/user_model.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

class AuthRepository {
  final AuthRemoteDatasource _datasource;
  final TokenStorage _storage;

  AuthRepository(this._datasource, this._storage);

  // ─── Token Management ───────────────────────────────────────────────────────

  Future<String?> getAccessToken() => _storage.read(_accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(_refreshTokenKey);

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(_accessTokenKey, accessToken),
      _storage.write(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(_accessTokenKey),
      _storage.delete(_refreshTokenKey),
    ]);
  }

  // ─── Auth State ──────────────────────────────────────────────────────────────

  /// Returns true if a local access token exists (optimistic check).
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAccessToken().timeout(const Duration(seconds: 2));
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  /// Exchange a Firebase ID token for Presso JWT.
  /// Throws [AuthException] on failure.
  Future<AuthResponse> login(
    String firebaseIdToken, {
    String? fcmToken,
    String? name,
    String? email,
  }) async {
    try {
      final authResponse = await _datasource.loginWithFirebase(
        firebaseIdToken,
        fcmToken: fcmToken,
        name: name,
        email: email,
      );
      await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } on DioException catch (e) {
      throw AuthException(_extractDioError(e));
    } catch (e) {
      throw AuthException('Login failed. Please try again.');
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearTokens();
  }

  // ─── Profile ─────────────────────────────────────────────────────────────────

  /// Fetch the current user profile from the API.
  /// Throws [AuthException] on failure.
  Future<UserModel> getProfile() async {
    try {
      return await _datasource.getProfile();
    } on DioException catch (e) {
      throw AuthException(_extractDioError(e));
    } catch (e) {
      throw AuthException('Failed to load profile. Please try again.');
    }
  }

  /// Update the user's name and/or email.
  Future<UserModel> updateProfile({String? name, String? email}) async {
    try {
      return await _datasource.updateProfile(name: name, email: email);
    } on DioException catch (e) {
      throw AuthException(_extractDioError(e));
    } catch (e) {
      throw AuthException('Failed to update profile. Please try again.');
    }
  }

  /// Validate the stored JWT by calling /api/users/me.
  /// Returns the user if valid, null if the token has expired or is invalid.
  Future<UserModel?> validateAndGetCurrentUser() async {
    final hasToken = await isAuthenticated();
    if (!hasToken) return null;

    try {
      return await _datasource.getProfile();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        await _clearTokens();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update the FCM push token on the server.
  Future<void> updateFcmToken(String token) async {
    try {
      await _datasource.updateFcmToken(token);
    } catch (_) {
      // Non-critical; swallow silently.
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _extractDioError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

// ─── Exception ───────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authRemoteDatasourceProvider);
  return AuthRepository(datasource, tokenStorage);
});
