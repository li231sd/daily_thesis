import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks lightweight "not for me" signals per backend subject key
/// (e.g. 'physics', 'biology'). This is a soft signal, not a hard block —
/// see InterestMatcher.subjectForToday, which uses these counts to lightly
/// steer daily rotation away from subjects the user keeps skipping,
/// without ever fully excluding a subject they explicitly chose.
class FeedbackStorage {
  static const _key = 'subject_feedback_v1';

  Future<Map<String, int>> loadDislikeCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};

    return decoded.map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
  }

  Future<void> recordNotForMe(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await loadDislikeCounts();
    counts[subject] = (counts[subject] ?? 0) + 1;
    await prefs.setString(_key, jsonEncode(counts));
  }
}
