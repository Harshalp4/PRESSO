class FacilityOrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final int garmentCount;
  final List<String> serviceNames;
  final String status;
  final DateTime? statusUpdatedAt;
  final bool hasShoeItems;
  final String? specialInstructions;
  final String? facilityNotes;
  final bool isExpressDelivery;

  FacilityOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.garmentCount,
    required this.serviceNames,
    required this.status,
    this.statusUpdatedAt,
    this.hasShoeItems = false,
    this.specialInstructions,
    this.facilityNotes,
    this.isExpressDelivery = false,
  });

  factory FacilityOrderModel.fromJson(Map<String, dynamic> json) {
    return FacilityOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      customerName: json['customerName'] as String,
      garmentCount: json['garmentCount'] as int? ?? 0,
      serviceNames: (json['serviceNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.parse(json['statusUpdatedAt'] as String)
          : null,
      hasShoeItems: json['hasShoeItems'] as bool? ?? false,
      specialInstructions: json['specialInstructions'] as String?,
      facilityNotes: json['facilityNotes'] as String?,
      isExpressDelivery: json['isExpressDelivery'] as bool? ?? false,
    );
  }
}
