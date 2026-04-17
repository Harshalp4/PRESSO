class FacilityStatsModel {
  final int atFacility;
  final int washing;
  final int ironing;
  final int ready;
  final int deliveredToday;
  final double avgProcessingHours;

  FacilityStatsModel({
    required this.atFacility,
    required this.washing,
    required this.ironing,
    required this.ready,
    required this.deliveredToday,
    required this.avgProcessingHours,
  });

  factory FacilityStatsModel.fromJson(Map<String, dynamic> json) {
    return FacilityStatsModel(
      atFacility: json['atFacility'] as int? ?? 0,
      washing: json['washing'] as int? ?? 0,
      ironing: json['ironing'] as int? ?? 0,
      ready: json['ready'] as int? ?? 0,
      deliveredToday: json['deliveredToday'] as int? ?? 0,
      avgProcessingHours:
          (json['avgProcessingHours'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
