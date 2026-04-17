import 'garment_type_model.dart';
import 'service_treatment_model.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double pricePerPiece;
  final String? iconUrl;
  final String? emoji;
  final bool isActive;
  final int sortOrder;
  final List<GarmentTypeModel> garmentTypes;
  final List<ServiceTreatmentModel> treatments;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.pricePerPiece,
    this.iconUrl,
    this.emoji,
    required this.isActive,
    required this.sortOrder,
    required this.garmentTypes,
    this.treatments = const [],
  });

  bool get hasTreatments => treatments.isNotEmpty;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawGarments = json['garmentTypes'] as List<dynamic>? ?? [];
    final rawTreatments = json['treatments'] as List<dynamic>? ?? [];
    return ServiceModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      pricePerPiece: (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      iconUrl: json['iconUrl'] as String?,
      emoji: json['emoji'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      garmentTypes: rawGarments
          .whereType<Map<String, dynamic>>()
          .map(GarmentTypeModel.fromJson)
          .toList(),
      treatments: rawTreatments
          .whereType<Map<String, dynamic>>()
          .map(ServiceTreatmentModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'pricePerPiece': pricePerPiece,
      if (iconUrl != null) 'iconUrl': iconUrl,
      if (emoji != null) 'emoji': emoji,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'garmentTypes': garmentTypes.map((g) => g.toJson()).toList(),
      if (treatments.isNotEmpty)
        'treatments': treatments.map((t) => t.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ServiceModel(id: $id, name: $name, category: $category)';
}
