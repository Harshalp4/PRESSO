class FacilityOrderDetailModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String status;
  final DateTime createdAt;
  final String? specialInstructions;
  final String? facilityNotes;
  final bool hasShoeItems;
  final bool isExpressDelivery;
  final int garmentCount;
  final List<OrderItemModel> items;
  final List<ShoeItemModel> shoeItems;
  final List<String> pickupPhotoUrls;
  final List<TimelineEntry> timeline;
  final String? pickupSlotDisplay;

  FacilityOrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.createdAt,
    this.specialInstructions,
    this.facilityNotes,
    this.hasShoeItems = false,
    this.isExpressDelivery = false,
    required this.garmentCount,
    required this.items,
    required this.shoeItems,
    required this.pickupPhotoUrls,
    required this.timeline,
    this.pickupSlotDisplay,
  });

  factory FacilityOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return FacilityOrderDetailModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      customerName: json['customerName'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      specialInstructions: json['specialInstructions'] as String?,
      facilityNotes: json['facilityNotes'] as String?,
      hasShoeItems: json['hasShoeItems'] as bool? ?? false,
      isExpressDelivery: json['isExpressDelivery'] as bool? ?? false,
      garmentCount: json['garmentCount'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      shoeItems: (json['shoeItems'] as List<dynamic>?)
              ?.map((e) => ShoeItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pickupPhotoUrls: (json['pickupPhotoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pickupSlotDisplay: json['pickupSlotDisplay'] as String?,
    );
  }
}

class OrderItemModel {
  final String serviceName;
  final String garmentTypeName;
  final int quantity;
  final double pricePerPiece;
  final double subtotal;
  final String? treatmentName;

  OrderItemModel({
    required this.serviceName,
    required this.garmentTypeName,
    required this.quantity,
    required this.pricePerPiece,
    required this.subtotal,
    this.treatmentName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      serviceName: json['serviceName'] as String,
      garmentTypeName: json['garmentTypeName'] as String,
      quantity: json['quantity'] as int? ?? 1,
      pricePerPiece: (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      treatmentName: json['treatmentName'] as String?,
    );
  }
}

class ShoeItemModel {
  final String id;
  final String shoeType;
  final String treatmentType;
  final int pairCount;
  final String? specialInstructions;
  final String? bagLabel;
  final double unitPrice;
  final double subtotal;
  final String status;
  final List<String> photoUrls;

  ShoeItemModel({
    required this.id,
    required this.shoeType,
    required this.treatmentType,
    required this.pairCount,
    this.specialInstructions,
    this.bagLabel,
    required this.unitPrice,
    required this.subtotal,
    required this.status,
    required this.photoUrls,
  });

  factory ShoeItemModel.fromJson(Map<String, dynamic> json) {
    return ShoeItemModel(
      id: json['id'] as String,
      shoeType: json['shoeType'] as String,
      treatmentType: json['treatmentType'] as String,
      pairCount: json['pairCount'] as int? ?? 1,
      specialInstructions: json['specialInstructions'] as String?,
      bagLabel: json['bagLabel'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class TimelineEntry {
  final String status;
  final DateTime timestamp;
  final String? note;

  TimelineEntry({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );
  }
}
