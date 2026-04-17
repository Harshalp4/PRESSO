class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String role;
  final bool isStudentVerified;
  final String referralCode;
  final int coinBalance;
  final String? profilePhotoUrl;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    required this.role,
    this.isStudentVerified = false,
    required this.referralCode,
    this.coinBalance = 0,
    this.profilePhotoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'customer',
      isStudentVerified: json['isStudentVerified'] as bool? ?? false,
      referralCode: json['referralCode'] as String? ?? '',
      coinBalance: json['coinBalance'] as int? ?? 0,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      'role': role,
      'isStudentVerified': isStudentVerified,
      'referralCode': referralCode,
      'coinBalance': coinBalance,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    bool? isStudentVerified,
    String? referralCode,
    int? coinBalance,
    String? profilePhotoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isStudentVerified: isStudentVerified ?? this.isStudentVerified,
      referralCode: referralCode ?? this.referralCode,
      coinBalance: coinBalance ?? this.coinBalance,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, phone: $phone, name: $name, role: $role)';
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}
