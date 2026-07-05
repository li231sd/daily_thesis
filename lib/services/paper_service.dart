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
  /// time.
  Future<Paper> fetchDailyPaper({List<String>? matchedSubjects}) async {
    final subject = (matchedSubjects == null || matchedSubjects.isEmpty)
        ? null
        : InterestMatcher.subjectForToday(matchedSubjects);

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
}
