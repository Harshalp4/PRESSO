class EarningsResponse {
  final double totalEarnings;
  final int jobCount;
  final int pickupCount;
  final int deliveryCount;
  final List<DailyEarning> dailyBreakdown;
  final List<RecentJob> recentJobs;

  EarningsResponse({
    required this.totalEarnings,
    required this.jobCount,
    required this.pickupCount,
    required this.deliveryCount,
    this.dailyBreakdown = const [],
    this.recentJobs = const [],
  });

  factory EarningsResponse.fromJson(Map<String, dynamic> json) {
    return EarningsResponse(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      jobCount: json['jobCount'] as int? ?? 0,
      pickupCount: json['pickupCount'] as int? ?? 0,
      deliveryCount: json['deliveryCount'] as int? ?? 0,
      dailyBreakdown: (json['dailyBreakdown'] as List<dynamic>?)
              ?.map((e) => DailyEarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentJobs: (json['recentJobs'] as List<dynamic>?)
              ?.map((e) => RecentJob.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DailyEarning {
  final String date;
  final double earnings;
  final int jobCount;

  DailyEarning({
    required this.date,
    required this.earnings,
    required this.jobCount,
  });

  factory DailyEarning.fromJson(Map<String, dynamic> json) {
    return DailyEarning(
      date: json['date'] as String? ?? '',
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0,
      jobCount: json['jobCount'] as int? ?? 0,
    );
  }
}

class RecentJob {
  final String orderId;
  final String orderNumber;
  final String type;
  final double amount;
  final DateTime? completedAt;
  final String? customerName;

  RecentJob({
    required this.orderId,
    required this.orderNumber,
    required this.type,
    required this.amount,
    this.completedAt,
    this.customerName,
  });

  factory RecentJob.fromJson(Map<String, dynamic> json) {
    return RecentJob(
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      customerName: json['customerName'] as String?,
    );
  }
}
