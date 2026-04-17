class OrderItemModel {
  final String id;
  final String serviceName;
  final String garmentTypeName;
  final int quantity;
  final double pricePerPiece;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.serviceName,
    required this.garmentTypeName,
    required this.quantity,
    required this.pricePerPiece,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] as int? ?? 1;
    final price = (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0;
    return OrderItemModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      garmentTypeName: json['garmentTypeName'] as String? ?? '',
      quantity: qty,
      pricePerPiece: price,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (price * qty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'garmentTypeName': garmentTypeName,
      'quantity': quantity,
      'pricePerPiece': pricePerPiece,
      'subtotal': subtotal,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderItemModel(id: $id, service: $serviceName, garment: $garmentTypeName, qty: $quantity)';
}
