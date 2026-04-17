import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial);

  Future<void> login(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.login(phone, otp);

    if (response.success && response.data != null) {
      // API returns: { data: { accessToken, refreshToken, user: { id, role, name, ... } } }
      final data = response.data!;
      final user = data['user'] as Map<String, dynamic>?;
      final role = user?['role'] as String? ?? data['role'] as String?;
      final name = user?['name'] as String? ?? data['name'] as String? ?? '';
      final userId = user?['id']?.toString() ?? data['id']?.toString() ?? '';
      final phone = user?['phone'] as String? ?? data['phone'] as String?;

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        userName: name,
        userId: userId,
        phone: phone,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.message,
      );
    }
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, error: null);

    final token = await _repository.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    final response = await _repository.getMe();

    if (response.success && response.data != null) {
      // /api/users/me returns: { data: { id, role, name, ... } }
      final userData = response.data!;
      final role = userData['role'] as String?;
      final name = userData['name'] as String? ?? '';
      final userId = userData['id']?.toString() ?? '';
      final phone = userData['phone'] as String?;

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        userName: name,
        userId: userId,
        phone: phone,
      );
    } else {
      await _repository.clearToken();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  Future<void> logout() async {
    await _repository.clearToken();
    state = AuthState.initial;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
