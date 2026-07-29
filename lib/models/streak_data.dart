enum DayStatus { completed, frozen, missed }

class StreakData {
  final Map<String, DayStatus> history;
  final int longestStreak;
  final int freezesAvailable;
  final List<int> milestonesReached;

  const StreakData({
    this.history = const {},
    this.longestStreak = 0,
    this.freezesAvailable = 0,
    this.milestonesReached = const [],
  });

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Consecutive completed days, with frozen days preserving the run without 
  /// adding to the count. If today hasn't been logged yet, this counts back 
  /// from yesterday instead of today — the streak isn't broken just because 
  /// the current day is still in progress. It only drops to a shorter run 
  /// (or 0) once a day is actually recorded as missed.
  int get currentStreak {
    int streak = 0;
    var day = DateTime.now();

    final todayStatus = history[dateKey(day)];
    if (todayStatus != DayStatus.completed && todayStatus != DayStatus.frozen) {
      day = day.subtract(const Duration(days: 1));
    }

    while (true) {
      final status = history[dateKey(day)];
      if (status == DayStatus.completed) {
        streak++; // Increment count for completed days
        day = day.subtract(const Duration(days: 1));
      } else if (status == DayStatus.frozen) {
        // Preserve the streak by stepping back, but do NOT increment the count
        day = day.subtract(const Duration(days: 1));
      } else {
        break; // A missed or unlogged day breaks the chain
      }
    }
    return streak;
  }

  /// True if the streak is active but today hasn't been logged yet.
  bool get atRisk {
    if (currentStreak == 0) return false;
    return history[dateKey(DateTime.now())] != DayStatus.completed;
  }

  StreakData copyWith({
    Map<String, DayStatus>? history,
    int? longestStreak,
    int? freezesAvailable,
    List<int>? milestonesReached,
  }) {
    return StreakData(
      history: history ?? this.history,
      longestStreak: longestStreak ?? this.longestStreak,
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      milestonesReached: milestonesReached ?? this.milestonesReached,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'history': history.map((k, v) => MapEntry(k, v.name)),
      'longestStreak': longestStreak,
      'freezesAvailable': freezesAvailable,
      'milestonesReached': milestonesReached,
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as Map<String, dynamic>? ?? {};
    return StreakData(
      history: rawHistory.map(
        (k, v) => MapEntry(k, DayStatus.values.byName(v as String)),
      ),
      longestStreak: json['longestStreak'] as int? ?? 0,
      freezesAvailable: json['freezesAvailable'] as int? ?? 0,
      milestonesReached: (json['milestonesReached'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }
}
