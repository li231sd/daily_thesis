import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paper.dart';
import 'interest_matcher.dart';

class PaperService {
  static const String _workerUrl =
      'https://quiet-bread-7971.li231sdyt.workers.dev/';

  /// Fetches today's paper. If the user has multiple matched subjects,
  /// rotates deterministically through them by day (see
  /// InterestMatcher.subjectForToday) so the same subject isn't hit every
  /// time. Pass [dislikeCounts] (from FeedbackStorage) to softly steer
  /// rotation away from subjects the user keeps marking "not for me".
  Future<Paper> fetchDailyPaper({
    List<String>? matchedSubjects,
    Map<String, int>? dislikeCounts,
  }) async {
    final subject = (matchedSubjects == null || matchedSubjects.isEmpty)
        ? null
        : InterestMatcher.subjectForToday(matchedSubjects, dislikeCounts: dislikeCounts);

    final uri = subject != null
        ? Uri.parse('$_workerUrl?subject=$subject')
        : Uri.parse(_workerUrl);

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final results = switch (decoded) {
      List<dynamic> items => items,
      Map<String, dynamic> json => (json['data'] as List<dynamic>?) ?? const [],
      _ => const [],
    };

    if (results.isEmpty) {
      throw Exception('No papers found');
    }

    final today = DateTime.now();
    final index =
        (today.year * 365 + today.month * 30 + today.day) % results.length;

    return Paper.fromJson(results[index] as Map<String, dynamic>);
  }

  /// Fetches a different paper for [subject] — used by the "not for me"
  /// feedback loop. Walks forward from the day's base index (offset by
  /// [attempt]) to find a paper not already in [excludeUrls] (papers shown
  /// earlier this session), so repeated taps don't just cycle the same
  /// handful of results back and forth.
  Future<Paper> fetchAnotherPaper({
    required String subject,
    int attempt = 0,
    Set<String> excludeUrls = const {},
  }) async {
    final uri = Uri.parse('$_workerUrl?subject=$subject');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final results = switch (decoded) {
      List<dynamic> items => items,
      Map<String, dynamic> json => (json['data'] as List<dynamic>?) ?? const [],
      _ => const [],
    };

    if (results.isEmpty) {
      throw Exception('No papers found');
    }

    final today = DateTime.now();
    final baseIndex = today.year * 365 + today.month * 30 + today.day;

    for (var i = 0; i < results.length; i++) {
      final index = (baseIndex + attempt + i) % results.length;
      final candidate = Paper.fromJson(results[index] as Map<String, dynamic>);
      if (!excludeUrls.contains(candidate.url)) {
        return candidate;
      }
    }

    // Every result for this subject has already been shown today — just
    // return the next one in sequence rather than erroring out.
    final fallbackIndex = (baseIndex + attempt) % results.length;
    return Paper.fromJson(results[fallbackIndex] as Map<String, dynamic>);
  }
}
