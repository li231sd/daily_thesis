import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/paper.dart';

class PaperHistoryEntry {
  final Paper paper;
  final DateTime viewedAt;

  const PaperHistoryEntry({required this.paper, required this.viewedAt});

  Map<String, dynamic> toJson() => {
        'paper': paper.toJson(),
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory PaperHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaperHistoryEntry(
      paper: Paper.fromJson(json['paper'] as Map<String, dynamic>),
      viewedAt: DateTime.tryParse(json['viewedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PaperHistoryStorage {
  static const _key = 'paper_history_v1';
  static const int _maxEntries = 40;

  String _dayKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Future<List<PaperHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PaperHistoryEntry.fromJson)
        .toList();
  }

  Future<void> saveDailyRecommendation(Paper paper) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final todayKey = _dayKey(DateTime.now());

    final filtered = current
        .where((entry) => _dayKey(entry.viewedAt) != todayKey)
        .toList();

    filtered.insert(0, PaperHistoryEntry(paper: paper, viewedAt: DateTime.now()));

    await prefs.setString(
      _key,
      jsonEncode(filtered.take(_maxEntries).map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}