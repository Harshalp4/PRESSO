class ServiceZoneModel {
  final String id;
  final String name;
  final String pincode;
  final String city;
  final String? area;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final String? assignedStoreId;
  final String? assignedStoreName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceZoneModel({
    required this.id,
    required this.name,
    required this.pincode,
    required this.city,
    this.area,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    this.assignedStoreId,
    this.assignedStoreName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceZoneModel.fromJson(Map<String, dynamic> json) {
    return ServiceZoneModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      assignedStoreId: json['assignedStoreId'] as String?,
      assignedStoreName: json['assignedStoreName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pincode': pincode,
      'city': city,
      if (area != null) 'area': area,
      if (description != null) 'description': description,
      if (assignedStoreId != null) 'assignedStoreId': assignedStoreId,
    };
  }

  ServiceZoneModel copyWith({
    String? id,
    String? name,
    String? pincode,
    String? city,
    String? area,
    String? description,
    bool? isActive,
    int? sortOrder,
    String? assignedStoreId,
    String? assignedStoreName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      area: area ?? this.area,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      assignedStoreId: assignedStoreId ?? this.assignedStoreId,
      assignedStoreName: assignedStoreName ?? this.assignedStoreName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceZoneModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
