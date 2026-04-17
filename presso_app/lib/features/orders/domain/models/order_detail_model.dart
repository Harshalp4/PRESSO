import 'package:presso_app/features/orders/domain/models/order_item_model.dart';

class OrderDetailModel {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double subTotal;
  final double coinDiscount;
  final double studentDiscount;
  final double adminDiscount;
  final double expressCharge;
  final double totalAmount;
  final bool isExpressDelivery;
  final String? specialInstructions;
  final int coinsEarned;
  final int coinsRedeemed;
  final List<String> pickupPhotoUrls;
  final String? razorpayOrderId;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  // Facility sub-stage + stage timestamps returned by the backend. Used to
  // drive the customer tracker past "At facility" into Processing / Ready /
  // Out for delivery. Stage is one of "AtFacility" / "Washing" / "Ironing"
  // / "Ready" (null when the order hasn't reached the facility yet).
  final String? facilityStage;
  final DateTime? facilityReceivedAt;
  final DateTime? processingStartedAt;
  final DateTime? readyAt;
  final DateTime? outForDeliveryAt;
  // 4-digit plaintext delivery OTP, surfaced only while the order is
  // OutForDelivery so the customer can show it to the rider at the door.
  final String? deliveryOtp;
  final DateTime createdAt;
  final OrderAddressInfo? address;
  final OrderSlotInfo? pickupSlot;
  final List<OrderItemModel> items;
  final List<OrderAssignment> assignments;
  final OrderFacilityInfo? facilityInfo;

  const OrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.subTotal,
    this.coinDiscount = 0.0,
    this.studentDiscount = 0.0,
    this.adminDiscount = 0.0,
    this.expressCharge = 0.0,
    required this.totalAmount,
    this.isExpressDelivery = false,
    this.specialInstructions,
    this.coinsEarned = 0,
    this.coinsRedeemed = 0,
    this.pickupPhotoUrls = const [],
    this.razorpayOrderId,
    this.pickedUpAt,
    this.deliveredAt,
    this.facilityStage,
    this.facilityReceivedAt,
    this.processingStartedAt,
    this.readyAt,
    this.outForDeliveryAt,
    this.deliveryOtp,
    required this.createdAt,
    this.address,
    this.pickupSlot,
    this.items = const [],
    this.assignments = const [],
    this.facilityInfo,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final photos = json['pickupPhotoUrls'] as List<dynamic>? ??
        json['pickupPhotos'] as List<dynamic>? ??
        [];
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final assignmentsJson = json['assignments'] as List<dynamic>? ?? [];

    return OrderDetailModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      subTotal: (json['subTotal'] as num?)?.toDouble() ??
          (json['subtotal'] as num?)?.toDouble() ??
          0.0,
      coinDiscount: (json['coinDiscount'] as num?)?.toDouble() ?? 0.0,
      studentDiscount: (json['studentDiscount'] as num?)?.toDouble() ?? 0.0,
      adminDiscount: (json['adminDiscount'] as num?)?.toDouble() ?? 0.0,
      expressCharge: (json['expressCharge'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      isExpressDelivery: json['isExpressDelivery'] as bool? ?? false,
      specialInstructions: json['specialInstructions'] as String?,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      coinsRedeemed: json['coinsRedeemed'] as int? ?? 0,
      pickupPhotoUrls: photos.map((e) => e.toString()).toList(),
      razorpayOrderId: json['razorpayOrderId'] as String?,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.tryParse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      facilityStage: json['facilityStage'] as String?,
      facilityReceivedAt: json['facilityReceivedAt'] != null
          ? DateTime.tryParse(json['facilityReceivedAt'] as String)
          : null,
      processingStartedAt: json['processingStartedAt'] != null
          ? DateTime.tryParse(json['processingStartedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'] as String)
          : null,
      outForDeliveryAt: json['outForDeliveryAt'] != null
          ? DateTime.tryParse(json['outForDeliveryAt'] as String)
          : null,
      deliveryOtp: json['deliveryOtp'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      address: json['address'] != null
          ? OrderAddressInfo.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      pickupSlot: json['pickupSlot'] != null
          ? OrderSlotInfo.fromJson(json['pickupSlot'] as Map<String, dynamic>)
          : null,
      items: itemsJson
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: assignmentsJson
          .map((e) => OrderAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      facilityInfo: json['facilityInfo'] != null
          ? OrderFacilityInfo.fromJson(
              json['facilityInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  /// Collapses the raw [status] + [facilityStage] returned by the backend
  /// into a single lowercase key the UI can switch on. The API returns the
  /// OrderStatus enum on customer endpoints (e.g. "InProcess"), plus the
  /// facility sub-stage as a separate field. Callers in the tracker /
  /// detail / history screens should use this rather than [status] directly
  /// so the InProcess bucket expands into its washing / ironing / ready
  /// children and stays in sync with the facility + rider apps.
  String get effectiveStatus {
    final s = status.toLowerCase();
    if ((s == 'inprocess' || s == 'in_process') &&
        facilityStage != null && facilityStage!.isNotEmpty) {
      return facilityStage!.toLowerCase();
    }
    return s;
  }

  String get statusLabel {
    switch (effectiveStatus) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'riderassigned':
      case 'rider_assigned':
        return 'Rider Assigned';
      case 'pickupinprogress':
        return 'Pickup in Progress';
      case 'picked_up':
      case 'pickedup':
        return 'Picked Up';
      case 'at_facility':
      case 'atfacility':
        return 'At Facility';
      case 'washing':
        return 'Washing';
      case 'ironing':
        return 'Ironing';
      case 'processing':
      case 'inprocess':
      case 'in_process':
        return 'Processing';
      case 'ready':
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return 'Ready for Delivery';
      case 'out_for_delivery':
      case 'outfordelivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderDetailModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderDetailModel(id: $id, orderNumber: $orderNumber, status: $status)';
}

class OrderAddressInfo {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? pincode;

  const OrderAddressInfo({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.pincode,
  });

  factory OrderAddressInfo.fromJson(Map<String, dynamic> json) {
    return OrderAddressInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ??
          json['line1'] as String? ??
          '',
      addressLine2: json['addressLine2'] as String? ?? json['line2'] as String?,
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? json['postalCode'] as String?,
    );
  }

  String get fullAddress {
    final parts = [addressLine1, if (addressLine2 != null) addressLine2!, city];
    return parts.join(', ');
  }
}

class OrderSlotInfo {
  final String id;
  final String date;
  final String startTime;
  final String endTime;

  const OrderSlotInfo({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory OrderSlotInfo.fromJson(Map<String, dynamic> json) {
    return OrderSlotInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }

  String get displayTime => '$startTime – $endTime';
  String get displayFull => '$date · $startTime – $endTime';
}

class OrderAssignment {
  final String id;
  final String role;
  final String agentName;
  final String? agentPhone;
  final String? vehicleNumber;
  final double? rating;
  final String? profilePhotoUrl;

  const OrderAssignment({
    required this.id,
    required this.role,
    required this.agentName,
    this.agentPhone,
    this.vehicleNumber,
    this.rating,
    this.profilePhotoUrl,
  });

  factory OrderAssignment.fromJson(Map<String, dynamic> json) {
    return OrderAssignment(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      role: json['role'] as String? ?? 'rider',
      agentName: json['agentName'] as String? ??
          json['name'] as String? ??
          'Agent',
      agentPhone: json['agentPhone'] as String? ?? json['phone'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }
}

class OrderFacilityInfo {
  final String id;
  final String name;
  final String? address;
  final String? phone;

  const OrderFacilityInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory OrderFacilityInfo.fromJson(Map<String, dynamic> json) {
    return OrderFacilityInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
