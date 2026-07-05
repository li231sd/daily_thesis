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

  bool get isArxiv => source == 'arxiv';

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

    static String _authorsFromJson(dynamic authorsJson) {
      if (authorsJson is String) {
        return authorsJson.trim();
      }

      if (authorsJson is List<dynamic>) {
        final authorList = authorsJson
            .take(3)
            .map((a) => a is Map<String, dynamic>
                ? a['name'] as String? ?? ''
                : '')
            .where((name) => name.isNotEmpty)
            .join(', ');
        final totalAuthors = authorsJson.length;
        return totalAuthors > 3 ? '$authorList et al.' : authorList;
      }

      return '';
    }

  factory Paper.fromJson(Map<String, dynamic> json) {
      final authors = _authorsFromJson(json['authors']);

    return Paper(
      title: (json['title'] as String? ?? 'Untitled')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      abstract: (json['abstract'] as String? ?? 'No abstract available.')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
      authors: authors,
      journal: json['journal'] as String? ?? '',
      url: json['url'] as String? ?? '',
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
