import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_data.dart';

class StreakStorage {
  static const _key = 'streak_data';

  Future<StreakData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const StreakData();
    try {
      return StreakData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const StreakData();
    }
  }

  Future<void> save(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
