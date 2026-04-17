class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? role;
  final String? userName;
  final String? userId;
  final String? phone;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.role,
    this.userName,
    this.userId,
    this.phone,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? role,
    String? userName,
    String? userId,
    String? phone,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      error: error,
    );
  }

  static const initial = AuthState();

  bool get isRider => role == 'Rider';
  bool get isFacilityStaff => role == 'FacilityStaff';
  bool get isAdmin => role == 'Admin';
}
