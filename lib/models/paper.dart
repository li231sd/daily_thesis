import 'package:html_unescape/html_unescape.dart';

final _unescape = HtmlUnescape();

class Paper {
  final String title;
  final String abstract;
  final String authors;
  final String journal;
  final String url;
  final int? citationCount;
  final int? publishYear;
  final String source; // 'openalex' or 'arxiv'

  const Paper({
    required this.title,
    required this.abstract,
    required this.authors,
    required this.journal,
    required this.url,
    this.citationCount,
    this.publishYear,
    required this.source,
  });

  static const _preprintSources = {'arxiv', 'chemrxiv', 'biorxiv', 'medrxiv'};

  bool get isPreprint => _preprintSources.contains(source);

  String get sourceDisplayName {
    switch (source) {
      case 'arxiv':
        return 'arXiv';
      case 'chemrxiv':
        return 'ChemRxiv';
      case 'biorxiv':
        return 'bioRxiv';
      case 'medrxiv':
        return 'medRxiv';
      case 'pubmed':
        return 'PubMed';
      case 'semanticscholar':
        return 'Semantic Scholar';
      case 'openalex':
        return 'OpenAlex';
      default:
        return source;
    }
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'abstract': abstract,
        'authors': authors,
        'journal': journal,
        'url': url,
        'citationCount': citationCount,
        'publishYear': publishYear,
        'source': source,
      };

  /// Cleans raw text by unescaping HTML entities, replacing raw un-delimited
  /// LaTeX commands, and normalizing whitespace.
  static String _cleanText(String? rawText, {String fallback = ''}) {
    if (rawText == null || rawText.isEmpty) return fallback;

    // 1. Unescape HTML entities (e.g. &#x2009;, &amp;)
    var text = _unescape.convert(rawText);

    // 2. Fix common raw LaTeX markup without dollar delimiters
    text = text
        // Degrees: {\textdegree}, \textdegree, \degree
        .replaceAll(RegExp(r'\{\\textdegree\}|\\textdegree|\\degree'), '°')
        // Superscripts / Subscripts embedded in text (e.g., cm 3 or cm^3)
        .replaceAll(RegExp(r'\\text\{(\w+)\}'), r'$1')
        .replaceAll(RegExp(r'\\mathrm\{(\w+)\}'), r'$1')
        // Common Greek letters used outside math mode
        .replaceAll(RegExp(r'\\mu\b'), 'μ')
        .replaceAll(RegExp(r'\\alpha\b'), 'α')
        .replaceAll(RegExp(r'\\beta\b'), 'β')
        .replaceAll(RegExp(r'\\gamma\b'), 'γ')
        .replaceAll(RegExp(r'\\pm\b'), '±')
        .replaceAll(RegExp(r'\\times\b'), '×');

    // 3. Normalize remaining extra spaces
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _authorsFromJson(dynamic authorsJson) {
    if (authorsJson is String) {
      return _cleanText(authorsJson);
    }

    if (authorsJson is List<dynamic>) {
      final authorList = authorsJson
          .take(3)
          .map((a) => a is Map<String, dynamic>
              ? _cleanText(a['name'] as String?)
              : '')
          .where((name) => name.isNotEmpty)
          .join(', ');
      final totalAuthors = authorsJson.length;
      return totalAuthors > 3 ? '$authorList et al.' : authorList;
    }

    return '';
  }

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      title: _cleanText(json['title'] as String?, fallback: 'Untitled'),
      abstract: _cleanText(
        json['abstract'] as String?,
        fallback: 'No abstract available.',
      ),
      authors: _authorsFromJson(json['authors']),
      journal: _cleanText(json['journal'] as String?),
      url: (json['url'] as String? ?? '').trim(),
      citationCount: json['citationCount'] as int?,
      publishYear: (json['publishYear'] as int?) ?? (json['year'] as int?),
      source: json['source'] as String? ?? 'openalex',
    );
  }

  String citation() {
    final parts = <String>[];

    if (authors.isNotEmpty) {
      parts.add('$authors.');
    }

    if (publishYear != null) {
      parts.add('($publishYear).');
    }

    parts.add('$title.');

    if (journal.isNotEmpty) {
      parts.add('$journal.');
    }

    if (url.isNotEmpty) {
      parts.add(url);
    }

    return parts.join(' ');
  }
}