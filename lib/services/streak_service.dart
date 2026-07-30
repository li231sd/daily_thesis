import '../models/streak_data.dart';
import 'streak_storage.dart';

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool streakIncreased;
  final bool streakBroken;
  final bool freezeConsumed;
  final int freezesAvailable;
  final int previousStreak;
  final int? milestoneHit;

  StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakIncreased,
    required this.streakBroken,
    required this.freezeConsumed,
    required this.freezesAvailable,
    required this.previousStreak,
    this.milestoneHit,
  });
}

class StreakService {
  static const milestones = [3, 7, 14, 30, 50, 100, 200, 365];
  static const maxFreezes = 2;
  static const freezeEarnedEveryNDays = 7;

  final StreakStorage _storage;
  StreakService({StreakStorage? storage}) : _storage = storage ?? StreakStorage();

  Future<StreakData> getStreakData() async {
    return await _storage.load();
  }

  Future<bool> hasLoggedToday() async {
    final s = await _storage.load();
    final todayKey = StreakData.dateKey(DateTime.now());
    return s.history[todayKey] == DayStatus.completed;
  }

  /// Runs on app start/resume. Checks past unrecorded days and fills gaps with
  /// freezes (if available) or marks them as missed.
  Future<StreakResult> evaluateOnOpen() async {
    var s = await _storage.load();
    final previousStreak = s.currentStreak;
    final today = DateTime.now();

    // If there's no history at all (new user), nothing to evaluate
    if (s.history.isEmpty) {
      return StreakResult(
        currentStreak: 0,
        longestStreak: s.longestStreak,
        streakIncreased: false,
        streakBroken: false,
        freezeConsumed: false,
        freezesAvailable: s.freezesAvailable,
        previousStreak: 0,
      );
    }

    // Floor for how far back we're allowed to backfill. Prefer the
    // explicit firstActiveDate (set at true first install); fall back to
    // the earliest date already present in history for older/migrated
    // data that predates this field. Without this floor, the very first
    // time evaluateOnOpen() runs *after* a user's first completed day
    // (e.g. a lifecycle resume later that same session), history is no
    // longer empty, so the emptiness guard above no longer applies — and
    // the loop below would otherwise "fill the gap" on days before the
    // user ever opened the app, wrongly spending a freeze or recording a
    // miss on a day that was never actually part of any streak.
    final anchor = _earliestBound(s);

    DateTime check = today.subtract(const Duration(days: 1));
    final newHistory = Map<String, DayStatus>.from(s.history);
    var remainingFreezes = s.freezesAvailable;
    bool freezeConsumed = false;
    bool streakBroken = false;

    while (true) {
      final key = StreakData.dateKey(check);

      // 1. Stop scanning if we hit an already recorded date in history
      if (newHistory.containsKey(key)) {
        break;
      }

      // 2. Never backfill earlier than the user's first active day.
      if (anchor != null && check.isBefore(anchor)) {
        break;
      }

      // 3. Safety cap: Stop scanning if we go back further than 14 days 
      // to prevent infinite loops on orphaned/corrupted states
      if (today.difference(check).inDays > 14) {
        break;
      }

      // Handle missing day
      if (remainingFreezes > 0) {
        newHistory[key] = DayStatus.frozen;
        remainingFreezes--;
        freezeConsumed = true;
      } else {
        newHistory[key] = DayStatus.missed;
        streakBroken = true;
      }

      check = check.subtract(const Duration(days: 1));
    }

    s = s.copyWith(
      freezesAvailable: remainingFreezes,
      history: newHistory,
    );

    await _storage.save(s);

    return StreakResult(
      currentStreak: s.currentStreak,
      longestStreak: s.longestStreak,
      streakIncreased: false,
      streakBroken: streakBroken,
      freezeConsumed: freezeConsumed,
      freezesAvailable: s.freezesAvailable,
      previousStreak: previousStreak,
    );
  }

  /// Date-only floor before which evaluateOnOpen() must never write a
  /// history entry: the user's recorded firstActiveDate, or (for data that
  /// predates that field) the earliest date key already in history.
  DateTime? _earliestBound(StreakData s) {
    if (s.firstActiveDate != null) {
      final d = s.firstActiveDate!;
      return DateTime(d.year, d.month, d.day);
    }
    if (s.history.isEmpty) return null;
    DateTime? earliest;
    for (final key in s.history.keys) {
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final parsed = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      if (earliest == null || parsed.isBefore(earliest)) {
        earliest = parsed;
      }
    }
    return earliest;
  }

  /// Records reading/activity completion for today.
  Future<StreakResult> recordActivity() async {
    // Resolve gaps first
    final gapResult = await evaluateOnOpen();
    var s = await _storage.load();

    final todayKey = StreakData.dateKey(DateTime.now());
    final previousStreak = s.currentStreak;

    // Already logged today?
    if (s.history[todayKey] == DayStatus.completed) {
      return StreakResult(
        currentStreak: s.currentStreak,
        longestStreak: s.longestStreak,
        streakIncreased: false,
        streakBroken: false,
        freezeConsumed: gapResult.freezeConsumed,
        freezesAvailable: s.freezesAvailable,
        previousStreak: previousStreak,
      );
    }

    final newHistory = Map<String, DayStatus>.from(s.history);
    newHistory[todayKey] = DayStatus.completed;

    // Temporarily apply history to get new calculated streak
    var updatedTemp = s.copyWith(history: newHistory);
    final newStreak = updatedTemp.currentStreak;
    final newLongest = newStreak > s.longestStreak ? newStreak : s.longestStreak;

    // Award freeze every 7 days
    var newFreezes = s.freezesAvailable;
    if (newStreak > 0 &&
        newStreak % freezeEarnedEveryNDays == 0 &&
        newFreezes < maxFreezes) {
      newFreezes++;
    }

    // Check milestones
    int? milestoneHit;
    final newMilestones = List<int>.from(s.milestonesReached);
    if (milestones.contains(newStreak) && !newMilestones.contains(newStreak)) {
      newMilestones.add(newStreak);
      milestoneHit = newStreak;
    }

    final finalData = s.copyWith(
      history: newHistory,
      longestStreak: newLongest,
      freezesAvailable: newFreezes,
      milestonesReached: newMilestones,
    );

    await _storage.save(finalData);

    return StreakResult(
      currentStreak: finalData.currentStreak,
      longestStreak: finalData.longestStreak,
      streakIncreased: true,
      streakBroken: gapResult.streakBroken,
      freezeConsumed: gapResult.freezeConsumed,
      freezesAvailable: finalData.freezesAvailable,
      previousStreak: previousStreak,
      milestoneHit: milestoneHit,
    );
  }
}
