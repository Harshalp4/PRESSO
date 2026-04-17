class SlotModel {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final bool available;
  final int? remainingCount;
  /// True when the slot's start time has already passed (client-side flag).
  final bool isExpired;

  const SlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.available,
    this.remainingCount,
    this.isExpired = false,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    final remaining = json['remainingCount'] as int? ?? json['slotsLeft'] as int?;
    return SlotModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      available: json['available'] as bool? ?? (remaining != null && remaining > 0),
      remainingCount: remaining,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'available': available,
      if (remainingCount != null) 'remainingCount': remainingCount,
    };
  }

  String get displayTime => '$startTime – $endTime';

  bool get isFull => !available && (remainingCount == null || remainingCount == 0);

  bool get isLow => available && !isExpired && remainingCount != null && remainingCount! <= 2;

  /// Whether this slot can be selected by the user right now.
  bool get isSelectable => available && !isExpired;

  SlotModel copyWith({
    String? id,
    String? date,
    String? startTime,
    String? endTime,
    bool? available,
    int? remainingCount,
    bool? isExpired,
  }) {
    return SlotModel(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      available: available ?? this.available,
      remainingCount: remainingCount ?? this.remainingCount,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SlotModel(id: $id, date: $date, time: $startTime–$endTime, available: $available)';
}
