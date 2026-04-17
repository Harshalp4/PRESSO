class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final bool isExpressDelivery;
  final DateTime createdAt;
  final String pickupSlotDisplay;
  final int itemCount;
  final String serviceSummary;
  // Facility sub-stage shipped alongside [status] so the history list can
  // expand InProcess into Washing/Ironing/Ready without a detail fetch.
  final String? facilityStage;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.isExpressDelivery,
    required this.createdAt,
    required this.pickupSlotDisplay,
    this.itemCount = 0,
    this.serviceSummary = '',
    this.facilityStage,
  });

  /// Same logic as [OrderDetailModel.effectiveStatus] — collapses the
  /// coarse "InProcess" bucket into the live facility sub-stage so the
  /// history list mini-tracker lines up with the tracker screen.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if ((s == 'inprocess' || s == 'in_process') &&
        facilityStage != null && facilityStage!.isNotEmpty) {
      return facilityStage!.toLowerCase();
    }
    return s;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      isExpressDelivery: json['isExpressDelivery'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      pickupSlotDisplay: json['pickupSlotDisplay'] as String? ??
          _buildSlotDisplay(json['pickupSlot'] as Map<String, dynamic>?),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      serviceSummary: json['serviceSummary'] as String? ?? '',
      facilityStage: json['facilityStage'] as String?,
    );
  }

  static String _buildSlotDisplay(Map<String, dynamic>? slot) {
    if (slot == null) return '';
    final date = slot['date'] as String? ?? '';
    final start = slot['startTime'] as String? ?? '';
    final end = slot['endTime'] as String? ?? '';
    if (date.isEmpty) return '$start – $end';
    return '$date · $start – $end';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'status': status,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'isExpressDelivery': isExpressDelivery,
      'createdAt': createdAt.toIso8601String(),
      'pickupSlotDisplay': pickupSlotDisplay,
      'itemCount': itemCount,
      'serviceSummary': serviceSummary,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? status,
    String? paymentStatus,
    double? totalAmount,
    bool? isExpressDelivery,
    DateTime? createdAt,
    String? pickupSlotDisplay,
    int? itemCount,
    String? serviceSummary,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      isExpressDelivery: isExpressDelivery ?? this.isExpressDelivery,
      createdAt: createdAt ?? this.createdAt,
      pickupSlotDisplay: pickupSlotDisplay ?? this.pickupSlotDisplay,
      itemCount: itemCount ?? this.itemCount,
      serviceSummary: serviceSummary ?? this.serviceSummary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderModel(id: $id, orderNumber: $orderNumber, status: $status)';
}
