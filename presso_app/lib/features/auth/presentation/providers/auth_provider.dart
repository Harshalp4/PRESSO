import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presso_app/features/auth/data/auth_repository.dart';
import 'package:presso_app/features/auth/domain/models/user_model.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;
  bool get needsProfileSetup =>
      isAuthenticated && (user?.name == null || user!.name!.isEmpty);

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.id}, error: $errorMessage)';
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  // ─── Initialization ─────────────────────────────────────────────────────────

  /// Called on app start to determine initial auth state.
  /// Validates the stored JWT against the server.
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.validateAndGetCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────

  /// Exchange a Firebase ID token for Presso JWT + user.
  Future<void> login(
    String firebaseIdToken, {
    String? fcmToken,
    String? name,
    String? email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authResponse = await _repository.login(
        firebaseIdToken,
        fcmToken: fcmToken,
        name: name,
        email: email,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ─── Profile Update ──────────────────────────────────────────────────────────

  Future<bool> updateProfile({String? name, String? email}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final updatedUser =
          await _repository.updateProfile(name: name, email: email);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: updatedUser,
      );
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: 'Failed to update profile.',
      );
      return false;
    }
  }

  /// Reload the user profile from the server.
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      // Keep existing state on failure
    }
  }

  /// Update FCM token (fire-and-forget, no state change).
  Future<void> updateFcmToken(String token) async {
    await _repository.updateFcmToken(token);
  }

  /// Clear any error message without changing auth status.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// Convenience provider that exposes the current [UserModel] or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// True when auth is fully resolved (either authenticated or unauthenticated).
final authReadyProvider = Provider<bool>((ref) {
  final status = ref.watch(authProvider).status;
  return status != AuthStatus.initial && status != AuthStatus.loading;
});

/// True only when authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
