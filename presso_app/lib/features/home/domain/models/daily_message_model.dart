class DailyMessageModel {
  final String hindiText;
  final String englishText;
  final String category;
  final String date;

  const DailyMessageModel({
    required this.hindiText,
    required this.englishText,
    required this.category,
    required this.date,
  });

  factory DailyMessageModel.fromJson(Map<String, dynamic> json) {
    return DailyMessageModel(
      hindiText: json['hindiText'] as String? ?? json['hindi'] as String? ?? '',
      englishText:
          json['englishText'] as String? ?? json['english'] as String? ?? '',
      category: json['category'] as String? ?? 'motivation',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hindiText': hindiText,
      'englishText': englishText,
      'category': category,
      'date': date,
    };
  }

  DailyMessageModel copyWith({
    String? hindiText,
    String? englishText,
    String? category,
    String? date,
  }) {
    return DailyMessageModel(
      hindiText: hindiText ?? this.hindiText,
      englishText: englishText ?? this.englishText,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMessageModel &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          hindiText == other.hindiText;

  @override
  int get hashCode => Object.hash(hindiText, date);

  @override
  String toString() =>
      'DailyMessageModel(category: $category, date: $date, hindi: $hindiText)';
}
