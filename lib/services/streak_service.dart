import '../models/streak_data.dart';
import 'streak_storage.dart';

class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool streakIncreased;
  final bool streakBroken;
  final bool freezeConsumed;
  final int freezesAvailable;
  final int? milestoneHit; // non-null if a milestone was just reached
  final int previousStreak; // streak value before this evaluation ran

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

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// True if the qualifying activity has already been recorded today —
  /// used to skip starting the session timer again this session.
  Future<bool> hasLoggedToday() async {
    final s = await _storage.load();
    if (s.lastActiveDate == null) return false;
    return _dateOnly(s.lastActiveDate!) == _dateOnly(DateTime.now());
  }

  StreakResult _unchanged(StreakData s) => StreakResult(
        currentStreak: s.currentStreak,
        longestStreak: s.longestStreak,
        streakIncreased: false,
        streakBroken: false,
        freezeConsumed: false,
        freezesAvailable: s.freezesAvailable,
        previousStreak: s.currentStreak,
      );

  /// Call once per app session (launch/resume), BEFORE recording any new
  /// activity. Resolves whether a missed day should consume a freeze or
  /// break the streak, so the UI can reflect "streak at risk" state even
  /// before the user does anything today.
  Future<StreakResult> evaluateOnOpen() async {
    final s = await _storage.load();
    if (s.lastActiveDate == null) return _unchanged(s);

    final today = _dateOnly(DateTime.now());
    final gap = today.difference(_dateOnly(s.lastActiveDate!)).inDays;

    if (gap <= 1) return _unchanged(s); // still current, or already logged today

    final missedDays = gap - 1;
    if (missedDays <= s.freezesAvailable) {
      final updated = s.copyWith(
        freezesAvailable: s.freezesAvailable - missedDays,
        lastActiveDate: today.subtract(const Duration(days: 1)),
      );
      await _storage.save(updated);
      return StreakResult(
        currentStreak: updated.currentStreak,
        longestStreak: updated.longestStreak,
        streakIncreased: false,
        streakBroken: false,
        freezeConsumed: true,
        freezesAvailable: updated.freezesAvailable,
        previousStreak: s.currentStreak,
      );
    }

    final broken = s.currentStreak;
    final reset = s.copyWith(currentStreak: 0, clearLastActiveDate: true);
    await _storage.save(reset);
    return StreakResult(
      currentStreak: 0,
      longestStreak: reset.longestStreak,
      streakIncreased: false,
      streakBroken: broken > 0,
      freezeConsumed: false,
      freezesAvailable: reset.freezesAvailable,
      previousStreak: broken,
    );
  }

  /// Call when the user completes today's qualifying activity (e.g. opens
  /// the full paper). Safe to call more than once per day — only the
  /// first call each day changes anything.
  Future<StreakResult> recordActivity() async {
    final today = _dateOnly(DateTime.now());
    final current = await _storage.load();

    if (current.lastActiveDate != null &&
        _dateOnly(current.lastActiveDate!) == today) {
      return _unchanged(current); // already logged today
    }

    // Resolve any pending gap first, in case this runs without
    // evaluateOnOpen having run yet this session.
    final gapResult = await evaluateOnOpen();
    final s = await _storage.load();

    var newStreak = s.currentStreak + 1;
    var newLongest = newStreak > s.longestStreak ? newStreak : s.longestStreak;
    var newFreezes = s.freezesAvailable;

    // Earn 1 Streak Freeze (ice) every 7 days (capped at maxFreezes)
    if (newStreak % freezeEarnedEveryNDays == 0 && newFreezes < maxFreezes) {
      newFreezes += 1;
    }

    int? milestoneHit;
    final newMilestones = List<int>.from(s.milestonesReached);
    if (milestones.contains(newStreak) && !newMilestones.contains(newStreak)) {
      newMilestones.add(newStreak);
      milestoneHit = newStreak;
    }

    final updated = s.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActiveDate: today,
      freezesAvailable: newFreezes,
      milestonesReached: newMilestones,
    );
    await _storage.save(updated);

    return StreakResult(
      currentStreak: updated.currentStreak,
      longestStreak: updated.longestStreak,
      streakIncreased: true,
      streakBroken: gapResult.streakBroken,
      freezeConsumed: gapResult.freezeConsumed,
      freezesAvailable: updated.freezesAvailable,
      previousStreak: s.currentStreak,
      milestoneHit: milestoneHit,
    );
  }
}
