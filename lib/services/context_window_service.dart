import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of a context window request: a plain-language summary plus a
/// short list of key term definitions, generated (or served from cache)
/// by the context-window-worker.
class PaperContext {
  final String summary;
  final List<KeyTerm> keyTerms;
  final bool cached;

  const PaperContext({
    required this.summary,
    required this.keyTerms,
    required this.cached,
  });

  factory PaperContext.fromJson(Map<String, dynamic> json) {
    final termsJson = json['key_terms'] as List<dynamic>? ?? const [];
    return PaperContext(
      summary: json['summary'] as String? ?? '',
      keyTerms: termsJson
          .map((t) => KeyTerm.fromJson(t as Map<String, dynamic>))
          .toList(),
      cached: json['cached'] as bool? ?? false,
    );
  }
}

class KeyTerm {
  final String term;
  final String definition;

  const KeyTerm({required this.term, required this.definition});

  factory KeyTerm.fromJson(Map<String, dynamic> json) => KeyTerm(
        term: json['term'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
      );
}

/// Thrown when the worker's circuit breaker is open (upstream LLM provider
/// is failing/rate-limited). Callers should show a friendly "try again
/// later" state rather than a generic error.
class ContextUnavailableException implements Exception {
  final int retryAfterSeconds;
  const ContextUnavailableException(this.retryAfterSeconds);
}

class ContextWindowService {
  static const String _workerUrl =
      'https://shrill-limit-92cf.li231sdyt.workers.dev';

  /// Fetches (or triggers generation of) the context window for a paper.
  /// [paperId] should be a stable unique key for the paper — we use the
  /// paper's URL, since Paper has no separate id field.
  /// [title]/[abstract] are only required on a cache miss; the worker
  /// serves straight from KV on repeat requests for the same paper.
  /// [field] is the user's declared subject of interest, used to calibrate
  /// how much background the summary assumes.
  Future<PaperContext> fetchContext({
    required String paperId,
    required String title,
    required String abstract,
    String? field,
  }) async {
    final params = <String, String>{
      'title': title,
      'abstract': abstract,
      if (field != null && field.isNotEmpty) 'field': field,
    };

    final uri = Uri.parse('$_workerUrl/context/${Uri.encodeComponent(paperId)}')
        .replace(queryParameters: params);

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode == 503) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      throw ContextUnavailableException(
        (decoded['retry_after_seconds'] as int?) ?? 60,
      );
    }

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return PaperContext.fromJson(decoded);
  }
}
