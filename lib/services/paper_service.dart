import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paper.dart';
import 'interest_matcher.dart';

class PaperService {
  static const String _workerUrl =
      'https://quiet-bread-7971.li231sdyt.workers.dev/';
  static const List<String> _fallbackSubjects = [
    'computer-science',
    'medicine',
  ];

  /// Fetches today's paper. If the user has multiple matched subjects,
  /// rotates deterministically through them by day (see
  /// InterestMatcher.subjectForToday) so the same subject isn't hit every
  /// time.
  Future<Paper> fetchDailyPaper({List<String>? matchedSubjects}) async {
    final subject = (matchedSubjects == null || matchedSubjects.isEmpty)
        ? null
        : InterestMatcher.subjectForToday(matchedSubjects);

    final candidateSubjects = <String?>[
      subject,
      ..._fallbackSubjects.where((candidate) => candidate != subject),
      null,
    ];

    Exception? lastError;

    for (final candidate in candidateSubjects) {
      try {
        final uri = candidate != null
            ? Uri.parse('$_workerUrl?subject=$candidate')
            : Uri.parse(_workerUrl);

        final response = await http.get(uri).timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          lastError = Exception('Server returned ${response.statusCode}');
          continue;
        }

        final decoded = jsonDecode(response.body);
        final results = switch (decoded) {
          List<dynamic> items => items,
          Map<String, dynamic> json =>
            (json['data'] as List<dynamic>?) ?? const [],
          _ => const [],
        };

        if (results.isEmpty) {
          lastError = Exception('No papers found for ${candidate ?? 'all subjects'}');
          continue;
        }

        final today = DateTime.now();
        final index =
            (today.year * 365 + today.month * 30 + today.day) % results.length;

        return Paper.fromJson(results[index] as Map<String, dynamic>);
      } on Exception catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('No papers found');
  }
}
