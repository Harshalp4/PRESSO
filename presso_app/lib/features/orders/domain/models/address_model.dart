class AddressModel {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? pincode;
  final bool isDefault;
  final String type; // 'home' | 'work' | 'other'
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.pincode,
    this.isDefault = false,
    this.type = 'home',
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ??
          json['line1'] as String? ??
          '',
      addressLine2: json['addressLine2'] as String? ?? json['line2'] as String?,
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? json['postalCode'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      type: json['type'] as String? ?? 'home',
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      if (pincode != null) 'pincode': pincode,
      'isDefault': isDefault,
      'type': type,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  String get fullAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      if (pincode != null && pincode!.isNotEmpty) pincode!,
    ];
    return parts.join(', ');
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? pincode,
    bool? isDefault,
    String? type,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AddressModel(id: $id, label: $label, city: $city)';
}
