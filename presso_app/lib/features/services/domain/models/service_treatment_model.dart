class ServiceTreatmentModel {
  final String id;
  final String name;
  final String? description;
  final double priceMultiplier;
  final int sortOrder;
  final List<String> tags;

  const ServiceTreatmentModel({
    required this.id,
    required this.name,
    this.description,
    required this.priceMultiplier,
    required this.sortOrder,
    this.tags = const [],
  });

  factory ServiceTreatmentModel.fromJson(Map<String, dynamic> json) {
    return ServiceTreatmentModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      priceMultiplier: (json['priceMultiplier'] as num?)?.toDouble() ?? 1.0,
      sortOrder: json['sortOrder'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'priceMultiplier': priceMultiplier,
    'sortOrder': sortOrder,
    'tags': tags,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTreatmentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
