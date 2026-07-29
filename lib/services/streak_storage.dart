import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';

class StreakStorage {
  static const _key = 'streak_data_v2';

  Future<StreakData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    // No saved data at all — this is a first install. Start the user off
    // with 1 freeze so an early missed day doesn't immediately break a
    // streak they've barely started.
    if (raw == null) return const StreakData(freezesAvailable: 1);

    try {
      return StreakData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupted/unparseable data for an existing user — reset state,
      // but don't grant the first-install bonus freeze here.
      return const StreakData();
    }
  }

  Future<void> save(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
