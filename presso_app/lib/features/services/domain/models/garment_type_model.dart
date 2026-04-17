class GarmentTypeModel {
  final String id;
  final String serviceId;
  final String name;
  final String? emoji;
  final double? priceOverride;
  final int sortOrder;
  final bool isActive;

  const GarmentTypeModel({
    required this.id,
    required this.serviceId,
    required this.name,
    this.emoji,
    this.priceOverride,
    required this.sortOrder,
    this.isActive = true,
  });

  factory GarmentTypeModel.fromJson(Map<String, dynamic> json) {
    return GarmentTypeModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String?,
      priceOverride: (json['priceOverride'] as num?)?.toDouble(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'name': name,
      if (emoji != null) 'emoji': emoji,
      if (priceOverride != null) 'priceOverride': priceOverride,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GarmentTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GarmentTypeModel(id: $id, name: $name, serviceId: $serviceId)';
}
