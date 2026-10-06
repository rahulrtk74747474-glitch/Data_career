class ReminderSettings {
  const ReminderSettings({
    required this.dailyEnabled,
    required this.reviewEnabled,
    required this.dailyHour,
    required this.dailyMinute,
    required this.reviewHour,
    required this.reviewMinute,
  });

  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      dailyEnabled: false,
      reviewEnabled: false,
      dailyHour: 18,
      dailyMinute: 0,
      reviewHour: 19,
      reviewMinute: 0,
    );
  }

  final bool dailyEnabled;
  final bool reviewEnabled;
  final int dailyHour;
  final int dailyMinute;
  final int reviewHour;
  final int reviewMinute;

  ReminderSettings copyWith({
    bool? dailyEnabled,
    bool? reviewEnabled,
    int? dailyHour,
    int? dailyMinute,
    int? reviewHour,
    int? reviewMinute,
  }) {
    return ReminderSettings(
      dailyEnabled: dailyEnabled ?? this.dailyEnabled,
      reviewEnabled: reviewEnabled ?? this.reviewEnabled,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      reviewHour: reviewHour ?? this.reviewHour,
      reviewMinute: reviewMinute ?? this.reviewMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyEnabled': dailyEnabled,
        'reviewEnabled': reviewEnabled,
        'dailyHour': dailyHour,
        'dailyMinute': dailyMinute,
        'reviewHour': reviewHour,
        'reviewMinute': reviewMinute,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      dailyEnabled: (json['dailyEnabled'] as bool?) ?? false,
      reviewEnabled: (json['reviewEnabled'] as bool?) ?? false,
      dailyHour: _validHour((json['dailyHour'] as num?)?.toInt(), 18),
      dailyMinute: _validMinute((json['dailyMinute'] as num?)?.toInt(), 0),
      reviewHour: _validHour((json['reviewHour'] as num?)?.toInt(), 19),
      reviewMinute: _validMinute((json['reviewMinute'] as num?)?.toInt(), 0),
    );
  }

  static int _validHour(int? value, int fallback) {
    if (value == null || value < 0 || value > 23) return fallback;
    return value;
  }

  static int _validMinute(int? value, int fallback) {
    if (value == null || value < 0 || value > 59) return fallback;
    return value;
  }
}
