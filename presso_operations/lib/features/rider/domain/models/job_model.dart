class RiderJobsResponse {
  final List<AssignmentModel> pickupJobs;
  final List<AssignmentModel> toDropJobs;
  final List<AssignmentModel> atFacilityJobs;
  final List<AssignmentModel> deliveryJobs;
  final int completedToday;
  final int pendingCount;

  RiderJobsResponse({
    required this.pickupJobs,
    required this.toDropJobs,
    required this.atFacilityJobs,
    required this.deliveryJobs,
    required this.completedToday,
    required this.pendingCount,
  });

  factory RiderJobsResponse.fromJson(Map<String, dynamic> json) {
    return RiderJobsResponse(
      pickupJobs: (json['pickupJobs'] as List<dynamic>?)
              ?.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      toDropJobs: (json['toDropJobs'] as List<dynamic>?)
              ?.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      atFacilityJobs: (json['atFacilityJobs'] as List<dynamic>?)
              ?.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryJobs: (json['deliveryJobs'] as List<dynamic>?)
              ?.map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      completedToday: json['completedToday'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
    );
  }
}

class AssignmentModel {
  final String id;
  final String type;
  final String status;
  final DateTime? assignedAt;
  final DateTime? riderArrivedAt;
  final DateTime? completedAt;
  final AssignmentOrderModel? order;
  final CustomerModel? customer;
  final AddressModel? address;
  final DateTime? offerExpiresAt;
  final int? secondsRemaining;
  final double? payoutAmount;

  AssignmentModel({
    required this.id,
    required this.type,
    required this.status,
    this.assignedAt,
    this.riderArrivedAt,
    this.completedAt,
    this.order,
    this.customer,
    this.address,
    this.offerExpiresAt,
    this.secondsRemaining,
    this.payoutAmount,
  });

  bool get isOffered => status == 'Offered';

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
      riderArrivedAt: json['riderArrivedAt'] != null
          ? DateTime.tryParse(json['riderArrivedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      order: json['order'] != null
          ? AssignmentOrderModel.fromJson(json['order'] as Map<String, dynamic>)
          : null,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      offerExpiresAt: json['offerExpiresAt'] != null
          ? DateTime.tryParse(json['offerExpiresAt'] as String)
          : null,
      secondsRemaining: json['secondsRemaining'] as int?,
      payoutAmount: (json['payoutAmount'] as num?)?.toDouble(),
    );
  }
}

class NearestFacilityModel {
  final String id;
  final String name;
  final String? address;
  final double distanceKm;
  final int etaMinutes;

  NearestFacilityModel({
    required this.id,
    required this.name,
    this.address,
    required this.distanceKm,
    required this.etaMinutes,
  });

  factory NearestFacilityModel.fromJson(Map<String, dynamic> json) =>
      NearestFacilityModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        etaMinutes: json['etaMinutes'] as int? ?? 0,
      );
}

class AssignmentOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final int garmentCount;
  final String? serviceSummary;
  final String? specialInstructions;
  final bool hasShoeItems;
  final bool isExpressDelivery;
  final String? pickupSlotDisplay;
  final List<ShoeItemModel> shoeItems;
  final List<String> pickupPhotoUrls;
  // Facility pipeline telemetry — lets the rider history tracker expand the
  // InProcess bucket into Washing / Ironing / Ready so the rider sees the
  // same live view the customer and facility apps see.
  final String? facilityStage;
  final DateTime? facilityReceivedAt;
  final DateTime? processingStartedAt;
  final DateTime? readyAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;

  AssignmentOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.garmentCount,
    this.serviceSummary,
    this.specialInstructions,
    this.hasShoeItems = false,
    this.isExpressDelivery = false,
    this.pickupSlotDisplay,
    this.shoeItems = const [],
    this.pickupPhotoUrls = const [],
    this.facilityStage,
    this.facilityReceivedAt,
    this.processingStartedAt,
    this.readyAt,
    this.outForDeliveryAt,
    this.deliveredAt,
  });

  /// Single source of truth for rider UIs. Returns the facility sub-stage
  /// when the order is mid-process so a "Washing" / "Ironing" / "Ready" tick
  /// surfaces on the tracker rather than the generic "InProcess" bucket.
  String get effectiveStatus {
    if (status == 'InProcess' &&
        facilityStage != null && facilityStage!.isNotEmpty) {
      return facilityStage!;
    }
    return status;
  }

  factory AssignmentOrderModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(String key) {
      final v = json[key];
      return v is String ? DateTime.tryParse(v) : null;
    }

    return AssignmentOrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? '',
      garmentCount: json['garmentCount'] as int? ?? 0,
      serviceSummary: json['serviceSummary'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      hasShoeItems: json['hasShoeItems'] as bool? ?? false,
      isExpressDelivery: json['isExpressDelivery'] as bool? ?? false,
      pickupSlotDisplay: json['pickupSlotDisplay'] as String?,
      shoeItems: (json['shoeItems'] as List<dynamic>?)
              ?.map((e) => ShoeItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pickupPhotoUrls: (json['pickupPhotoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      facilityStage: json['facilityStage'] as String?,
      facilityReceivedAt: parseTs('facilityReceivedAt'),
      processingStartedAt: parseTs('processingStartedAt'),
      readyAt: parseTs('readyAt'),
      outForDeliveryAt: parseTs('outForDeliveryAt'),
      deliveredAt: parseTs('deliveredAt'),
    );
  }
}

class CustomerModel {
  final String name;
  final String maskedPhone;

  CustomerModel({
    required this.name,
    required this.maskedPhone,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      name: json['name'] as String? ?? '',
      maskedPhone: json['maskedPhone'] as String? ?? '',
    );
  }
}

class AddressModel {
  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String? city;
  final String? pincode;
  final double? latitude;
  final double? longitude;

  AddressModel({
    this.label,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.pincode,
    this.latitude,
    this.longitude,
  });

  String get fullAddress {
    final parts = <String>[addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      label: json['label'] as String?,
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Response payload from POST /api/riders/me/job/{id}/start-drop.
/// The rider displays [otp] to facility staff, who types it into the
/// facility app to verify receipt of the bag.
class DropOtpModel {
  final String otp;
  final DateTime expiresAt;
  final int secondsRemaining;

  const DropOtpModel({
    required this.otp,
    required this.expiresAt,
    required this.secondsRemaining,
  });

  factory DropOtpModel.fromJson(Map<String, dynamic> json) {
    return DropOtpModel(
      otp: json['otp'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      secondsRemaining: json['secondsRemaining'] as int? ?? 0,
    );
  }
}

class ShoeItemModel {
  final String id;
  final String? shoeType;
  final String? treatmentType;
  final int pairCount;
  final String? specialInstructions;
  final String? bagLabel;
  final double unitPrice;
  final double subtotal;
  final String? status;
  final List<String> photoUrls;

  ShoeItemModel({
    required this.id,
    this.shoeType,
    this.treatmentType,
    this.pairCount = 1,
    this.specialInstructions,
    this.bagLabel,
    this.unitPrice = 0,
    this.subtotal = 0,
    this.status,
    this.photoUrls = const [],
  });

  factory ShoeItemModel.fromJson(Map<String, dynamic> json) {
    return ShoeItemModel(
      id: json['id'] as String? ?? '',
      shoeType: json['shoeType'] as String?,
      treatmentType: json['treatmentType'] as String?,
      pairCount: json['pairCount'] as int? ?? 1,
      specialInstructions: json['specialInstructions'] as String?,
      bagLabel: json['bagLabel'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
