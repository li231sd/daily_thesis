class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate; // date-only, local time
  final int freezesAvailable;
  final List<int> milestonesReached;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.freezesAvailable = 1,
    this.milestonesReached = const [],
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    bool clearLastActiveDate = false,
    int? freezesAvailable,
    List<int>? milestonesReached,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate:
          clearLastActiveDate ? null : (lastActiveDate ?? this.lastActiveDate),
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      milestonesReached: milestonesReached ?? this.milestonesReached,
    );
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : null,
      freezesAvailable: json['freezesAvailable'] as int? ?? 1,
      milestonesReached: (json['milestonesReached'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'freezesAvailable': freezesAvailable,
      'milestonesReached': milestonesReached,
    };
  }
}
