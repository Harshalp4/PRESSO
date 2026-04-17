class CreateOrderRequest {
  final String addressId;
  final String? pickupSlotId;
  final List<OrderItemRequest> items;
  final bool isExpressDelivery;
  final String? specialInstructions;
  final int coinsToRedeem;

  const CreateOrderRequest({
    required this.addressId,
    this.pickupSlotId,
    required this.items,
    this.isExpressDelivery = false,
    this.specialInstructions,
    this.coinsToRedeem = 0,
  });

  /// Returns true if the pickupSlotId looks like a valid UUID (not a fallback).
  static bool _isValidGuid(String? id) {
    if (id == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      // Only send pickupSlotId if it's a real GUID (not a fallback ID)
      if (_isValidGuid(pickupSlotId)) 'pickupSlotId': pickupSlotId,
      'items': items.map((e) => e.toJson()).toList(),
      'isExpressDelivery': isExpressDelivery,
      if (specialInstructions != null && specialInstructions!.isNotEmpty)
        'specialInstructions': specialInstructions,
      if (coinsToRedeem > 0) 'coinsToRedeem': coinsToRedeem,
    };
  }

  @override
  String toString() =>
      'CreateOrderRequest(addressId: $addressId, slotId: $pickupSlotId, items: ${items.length})';
}

class OrderItemRequest {
  final String serviceId;
  final String garmentTypeId;
  final int quantity;
  final String? serviceTreatmentId;

  const OrderItemRequest({
    required this.serviceId,
    required this.garmentTypeId,
    required this.quantity,
    this.serviceTreatmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'garmentTypeId': garmentTypeId,
      'quantity': quantity,
      if (serviceTreatmentId != null) 'serviceTreatmentId': serviceTreatmentId,
    };
  }
}
