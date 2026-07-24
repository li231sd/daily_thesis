import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which papers (by URL) the user has explicitly marked "not for me".
///
/// This is what was missing before: FeedbackStorage only tracks a soft,
/// subject-level dislike *count* used to steer subject rotation, but never
/// remembered which specific paper was rejected. LikedPapersStorage only
/// tracks the opposite signal. Without a per-paper "dismissed" record,
/// PaperService.fetchDailyPaper's date-based index had no way to know a
/// paper had already been rejected, so refreshing (which clears the
/// session-only `_shownUrlsToday` set in PaperScreen) could re-serve it.
///
/// URLs stored here are persisted across app restarts and merged into the
/// exclude list passed to PaperService, so a dismissed paper is gone for
/// good — not just for the current session.
class DismissedPapersStorage {
  static const _key = 'dismissed_papers_v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> add(String url) async {
    if (url.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.add(url);
    await prefs.setStringList(_key, current.toList());
  }

  /// Clears every dismissed paper. Mainly useful for a future "reset
  /// recommendations" settings option.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}