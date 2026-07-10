import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which papers (by URL) the user has liked. Purely a lightweight,
/// local "just for fun" signal — no backend effect, no subject weighting,
/// unlike the dislike/"not for me" signal in FeedbackStorage.
class LikedPapersStorage {
  static const _key = 'liked_papers_v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> setLiked(String url, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    if (liked) {
      current.add(url);
    } else {
      current.remove(url);
    }
    await prefs.setStringList(_key, current.toList());
  }
}
