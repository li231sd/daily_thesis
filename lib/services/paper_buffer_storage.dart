import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paper.dart';

/// A rolling queue of not-yet-shown papers, built up while online so the
/// app can still serve something fresh when there's no connection.
///
/// This is deliberately separate from PaperHistoryStorage: history is
/// "papers the user has seen", buffer is "papers fetched ahead of time,
/// waiting to be seen". A paper moves out of the buffer and into history
/// the moment it's actually shown (see PaperScreen).
class PaperBufferStorage {
  static const _key = 'paper_buffer_v1';

  /// How many unread papers to try to keep queued up.
  static const targetSize = 8;

  Future<List<Paper>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Paper.fromJson)
        .toList();
  }

  Future<void> _save(List<Paper> papers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(papers.map((p) => p.toJson()).toList()),
    );
  }

  /// Adds [candidates] to the buffer, skipping anything already queued or
  /// present in [excludeUrls] (e.g. already viewed). Stops once the buffer
  /// reaches [targetSize]. Safe to call opportunistically and often.
  Future<void> addIfRoom(
    List<Paper> candidates, {
    Set<String> excludeUrls = const {},
  }) async {
    // .toList() guarantees a growable copy — load() can return a const []
    // when the buffer is empty, and const lists throw on .add().
    final current = (await load()).toList();
    if (current.length >= targetSize) return;

    final known = {...excludeUrls, ...current.map((p) => p.url)};
    for (final paper in candidates) {
      if (current.length >= targetSize) break;
      if (paper.url.isEmpty || known.contains(paper.url)) continue;
      current.add(paper);
      known.add(paper.url);
    }
    await _save(current);
  }

  /// Removes and returns the next unread paper, or null if the buffer is
  /// empty (i.e. there's nothing left to show offline).
  Future<Paper?> popNext() async {
    final current = await load();
    if (current.isEmpty) return null;
    final next = current.removeAt(0);
    await _save(current);
    return next;
  }

  Future<int> count() async => (await load()).length;

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}