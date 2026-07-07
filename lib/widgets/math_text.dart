import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders [content] as flowing text, treating any `$...$` or `$$...$$`
/// segments as inline LaTeX rendered via flutter_math_fork.
///
/// Unlike flutter_tex's TeXView, this never spins up a WebView — it's
/// pure Flutter canvas rendering, so it performs identically on iOS and
/// Android and has none of the WebView startup/teardown cost.
///
/// Falls back to plain text automatically if no math delimiters are
/// found, so it's a safe drop-in replacement for a plain Text widget.
class MathText extends StatelessWidget {
  final String content;
  final TextStyle style;
  final TextAlign textAlign;

  const MathText(
    this.content, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans(content, style)),
      textAlign: textAlign,
    );
  }

  /// Matches `$$...$$` (display math) or `$...$` (inline math) and splits
  /// the surrounding plain text into separate spans.
  static final RegExp _mathPattern = RegExp(
    r'\$\$(.+?)\$\$|\$(.+?)\$',
    dotAll: true,
  );

  static List<InlineSpan> _buildSpans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _mathPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      final tex = (match.group(1) ?? match.group(2) ?? '').trim();
      if (tex.isEmpty) {
        // Not real math (e.g. a lone "$5" price) — keep the raw text.
        spans.add(TextSpan(text: match.group(0), style: style));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: Math.tex(
                tex,
                textStyle: style,
                mathStyle: MathStyle.text,
                onErrorFallback: (_) => Text(match.group(0) ?? '', style: style),
              ),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
    }

    return spans;
  }
}
