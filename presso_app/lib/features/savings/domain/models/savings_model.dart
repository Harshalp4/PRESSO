class SavingsModel {
  final double totalSaved;
  final double coinSavings;
  final double studentSavings;
  final double adminSavings;

  const SavingsModel({
    required this.totalSaved,
    required this.coinSavings,
    required this.studentSavings,
    required this.adminSavings,
  });

  factory SavingsModel.fromJson(Map<String, dynamic> json) {
    return SavingsModel(
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      coinSavings: (json['coinSavings'] as num?)?.toDouble() ?? 0.0,
      studentSavings: (json['studentSavings'] as num?)?.toDouble() ?? 0.0,
      adminSavings: (json['adminSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSaved': totalSaved,
        'coinSavings': coinSavings,
        'studentSavings': studentSavings,
        'adminSavings': adminSavings,
      };

  @override
  String toString() =>
      'SavingsModel(totalSaved: $totalSaved, coinSavings: $coinSavings)';
}

class CoinBalance {
  final int balance;
  final double valueInRupees;

  const CoinBalance({
    required this.balance,
    required this.valueInRupees,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      balance: json['balance'] as int? ?? 0,
      valueInRupees: (json['valueInRupees'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'valueInRupees': valueInRupees,
      };

  @override
  String toString() =>
      'CoinBalance(balance: $balance, valueInRupees: $valueInRupees)';
}

class LedgerEntry {
  final String id;
  final int amount;
  final String type;
  final String description;
  final String? orderNumber;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.orderNumber,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'description': description,
        if (orderNumber != null) 'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isCredit => amount > 0;

  @override
  String toString() =>
      'LedgerEntry(id: $id, amount: $amount, type: $type)';
}
