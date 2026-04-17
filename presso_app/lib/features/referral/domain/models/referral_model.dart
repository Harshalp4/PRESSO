class ReferralStats {
  final String code;
  final int referredCount;
  final int coinsEarned;
  final double totalSaved;

  const ReferralStats({
    required this.code,
    required this.referredCount,
    required this.coinsEarned,
    required this.totalSaved,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      code: json['code'] as String? ?? '',
      referredCount: json['referredCount'] as int? ?? 0,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'referredCount': referredCount,
        'coinsEarned': coinsEarned,
        'totalSaved': totalSaved,
      };

  @override
  String toString() =>
      'ReferralStats(code: $code, referredCount: $referredCount)';
}

class ReferralHistory {
  final String referredUserName;
  final String status;
  final int coinsEarned;
  final DateTime createdAt;

  const ReferralHistory({
    required this.referredUserName,
    required this.status,
    required this.coinsEarned,
    required this.createdAt,
  });

  factory ReferralHistory.fromJson(Map<String, dynamic> json) {
    return ReferralHistory(
      referredUserName: json['referredUserName'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'pending',
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'referredUserName': referredUserName,
        'status': status,
        'coinsEarned': coinsEarned,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isNotOrdered => status.toLowerCase() == 'not_ordered';

  @override
  String toString() =>
      'ReferralHistory(name: $referredUserName, status: $status)';
}
