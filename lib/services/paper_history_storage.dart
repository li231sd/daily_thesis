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

  /// Loads the complete list of viewed papers from local storage.
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

  /// Saves a newly viewed paper to the history timeline.
  /// 
  /// This allows multiple papers per day, ensures no duplicate entries exist 
  /// for the same paper (moving it to the top if re-viewed), and caps the history 
  /// length at [_maxEntries].
  Future<void> saveDailyRecommendation(Paper paper) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();

    // 1. Create a mutable working copy of the history
    final updated = List<PaperHistoryEntry>.from(current);

    // 2. Deduplicate: Remove the paper if it already exists anywhere in history.
    // If your Paper model has an 'id', you can use entry.paper.id == paper.id instead.
    updated.removeWhere((entry) => entry.paper.url == paper.url);

    // 3. Insert the fresh view entry at the front of the list
    updated.insert(0, PaperHistoryEntry(paper: paper, viewedAt: DateTime.now()));

    // 4. Persist the updated history list, trimming down to the maximum allowed entries
    await prefs.setString(
      _key,
      jsonEncode(updated.take(_maxEntries).map((entry) => entry.toJson()).toList()),
    );
  }

  /// Clears the entire viewing history.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
