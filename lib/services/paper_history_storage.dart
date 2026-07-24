import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paper.dart';

/// The user's reaction to a paper at the time it was last shown, so History
/// can display it. `liked`/`disliked` mirror LikedPapersStorage and
/// DismissedPapersStorage respectively — this enum just lets that signal
/// travel along with the history entry itself.
enum PaperFeedbackStatus { none, liked, disliked }

class PaperHistoryEntry {
  final Paper paper;
  final DateTime viewedAt;
  final PaperFeedbackStatus status;

  const PaperHistoryEntry({
    required this.paper,
    required this.viewedAt,
    this.status = PaperFeedbackStatus.none,
  });

  PaperHistoryEntry copyWith({PaperFeedbackStatus? status}) => PaperHistoryEntry(
        paper: paper,
        viewedAt: viewedAt,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'paper': paper.toJson(),
        'viewedAt': viewedAt.toIso8601String(),
        'status': status.name,
      };

  factory PaperHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaperHistoryEntry(
      paper: Paper.fromJson(json['paper'] as Map<String, dynamic>),
      viewedAt: DateTime.tryParse(json['viewedAt'] as String? ?? '') ?? DateTime.now(),
      status: PaperFeedbackStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaperFeedbackStatus.none,
      ),
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
  /// for the same paper (moving it to the top if re-viewed), and caps the
  /// history length at [_maxEntries].
  ///
  /// If [status] isn't provided, any existing like/dislike status already
  /// recorded for this URL is preserved instead of being reset to `none` —
  /// otherwise re-showing a previously-liked paper (e.g. from the offline
  /// buffer) would silently wipe out its liked badge in History.
  Future<void> saveDailyRecommendation(
    Paper paper, {
    PaperFeedbackStatus? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();

    // 1. Create a mutable working copy of the history
    final updated = List<PaperHistoryEntry>.from(current);

    // 2. Preserve prior status for this paper (if any) unless caller
    // explicitly overrides it.
    final existingIndex = updated.indexWhere((entry) => entry.paper.url == paper.url);
    final resolvedStatus = status ??
        (existingIndex != -1 ? updated[existingIndex].status : PaperFeedbackStatus.none);

    // 3. Deduplicate: Remove the paper if it already exists anywhere in history.
    // If your Paper model has an 'id', you can use entry.paper.id == paper.id instead.
    updated.removeWhere((entry) => entry.paper.url == paper.url);

    // 4. Insert the fresh view entry at the front of the list
    updated.insert(
      0,
      PaperHistoryEntry(paper: paper, viewedAt: DateTime.now(), status: resolvedStatus),
    );

    // 5. Persist the updated history list, trimming down to the maximum allowed entries
    await prefs.setString(
      _key,
      jsonEncode(updated.take(_maxEntries).map((entry) => entry.toJson()).toList()),
    );
  }

  /// Updates the like/dislike status of an existing history entry (matched
  /// by paper URL) without changing its position or viewedAt timestamp.
  /// No-op if the URL isn't in history yet.
  Future<void> updateStatus(String url, PaperFeedbackStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final index = current.indexWhere((entry) => entry.paper.url == url);
    if (index == -1) return;

    final updated = List<PaperHistoryEntry>.from(current);
    updated[index] = updated[index].copyWith(status: status);

    await prefs.setString(
      _key,
      jsonEncode(updated.map((entry) => entry.toJson()).toList()),
    );
  }

  /// Clears the entire viewing history.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
