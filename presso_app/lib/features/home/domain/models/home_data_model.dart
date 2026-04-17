class HomeDataModel {
  // User info
  final String userId;
  final String userName;
  final String userPhone;
  final String? userProfilePhotoUrl;
  final String referralCode;

  // Active order summary
  final ActiveOrderSummary? activeOrder;

  // Savings
  final double savingsTotal;
  final int totalOrderCount;

  // Coin balance
  final int coinBalance;
  final String coinTier;
  final int coinsToNextTier;
  final String nextTierName;

  const HomeDataModel({
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.userProfilePhotoUrl,
    required this.referralCode,
    this.activeOrder,
    this.savingsTotal = 0.0,
    this.totalOrderCount = 0,
    this.coinBalance = 0,
    this.coinTier = 'Silver',
    this.coinsToNextTier = 500,
    this.nextTierName = 'Gold',
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final savingsJson = json['savings'] as Map<String, dynamic>? ?? {};
    final coinsJson = json['coins'] as Map<String, dynamic>? ?? {};
    final activeOrderJson =
        json['activeOrder'] as Map<String, dynamic>?;

    return HomeDataModel(
      userId: userJson['id'] as String? ?? userJson['_id'] as String? ?? '',
      userName: userJson['name'] as String? ?? 'User',
      userPhone: userJson['phone'] as String? ?? '',
      userProfilePhotoUrl: userJson['profilePhotoUrl'] as String?,
      referralCode: userJson['referralCode'] as String? ?? '',
      activeOrder: activeOrderJson != null
          ? ActiveOrderSummary.fromJson(activeOrderJson)
          : null,
      savingsTotal:
          (savingsJson['totalSaved'] as num?)?.toDouble() ??
              (savingsJson['total'] as num?)?.toDouble() ??
              0.0,
      totalOrderCount: savingsJson['orderCount'] as int? ?? 0,
      coinBalance: coinsJson['balance'] as int? ?? 0,
      coinTier: coinsJson['tier'] as String? ?? 'Silver',
      coinsToNextTier: coinsJson['coinsToNextTier'] as int? ?? 500,
      nextTierName: coinsJson['nextTierName'] as String? ?? 'Gold',
    );
  }

  HomeDataModel copyWith({
    String? userId,
    String? userName,
    String? userPhone,
    String? userProfilePhotoUrl,
    String? referralCode,
    ActiveOrderSummary? activeOrder,
    double? savingsTotal,
    int? totalOrderCount,
    int? coinBalance,
    String? coinTier,
    int? coinsToNextTier,
    String? nextTierName,
  }) {
    return HomeDataModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userProfilePhotoUrl: userProfilePhotoUrl ?? this.userProfilePhotoUrl,
      referralCode: referralCode ?? this.referralCode,
      activeOrder: activeOrder ?? this.activeOrder,
      savingsTotal: savingsTotal ?? this.savingsTotal,
      totalOrderCount: totalOrderCount ?? this.totalOrderCount,
      coinBalance: coinBalance ?? this.coinBalance,
      coinTier: coinTier ?? this.coinTier,
      coinsToNextTier: coinsToNextTier ?? this.coinsToNextTier,
      nextTierName: nextTierName ?? this.nextTierName,
    );
  }
}

class ActiveOrderSummary {
  final String orderId;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final String? agentName;
  final List<String> photoUrls;
  final int currentStep; // 0=Picked, 1=Facility, 2=Processing, 3=Delivery
  final String? estimatedDelivery;

  const ActiveOrderSummary({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    this.agentName,
    this.photoUrls = const [],
    this.currentStep = 0,
    this.estimatedDelivery,
  });

  factory ActiveOrderSummary.fromJson(Map<String, dynamic> json) {
    final photos = json['pickupPhotos'] as List<dynamic>? ?? [];
    return ActiveOrderSummary(
      orderId: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderNumber:
          json['orderNumber'] as String? ?? json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? 'processing',
      statusLabel: json['statusLabel'] as String? ?? 'In Progress',
      agentName: json['agentName'] as String?,
      photoUrls: photos.map((e) => e.toString()).toList(),
      currentStep: json['currentStep'] as int? ?? 2,
      estimatedDelivery: json['estimatedDelivery'] as String?,
    );
  }
}
