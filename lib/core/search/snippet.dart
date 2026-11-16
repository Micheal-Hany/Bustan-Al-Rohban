import 'arabic_normalizer.dart';

/// An excerpt of the ORIGINAL paragraph text with ranges to highlight.
/// [text] is an exact substring of the original (never normalized).
class SearchSnippet {
  const SearchSnippet({
    required this.text,
    required this.highlights,
    required this.truncatedStart,
    required this.truncatedEnd,
  });

  final String text;

  /// (start, end) ranges inside [text].
  final List<(int, int)> highlights;
  final bool truncatedStart;
  final bool truncatedEnd;
}

bool _isSpace(int c) => String.fromCharCode(c).trim().isEmpty;

bool _tokenMatches(String token, List<String> query) {
  for (final q in query) {
    if (token == q || (q.length >= 2 && token.startsWith(q))) return true;
  }
  return false;
}

/// Builds an excerpt of at most about [maxLength] characters around the first
/// match of [query] (normalized tokens, see [queryTokens]).
SearchSnippet buildSnippet(
  String original,
  List<String> query, {
  int maxLength = 160,
}) {
  final matches = [
    for (final t in tokenizeArabic(original))
      if (_tokenMatches(t.value, query)) t,
  ];
  final n = original.length;
  if (n == 0) {
    return const SearchSnippet(
      text: '',
      highlights: [],
      truncatedStart: false,
      truncatedEnd: false,
    );
  }

  var from = 0;
  if (matches.isNotEmpty) {
    from = matches.first.start - maxLength ~/ 3;
    if (from < 0) from = 0;
  }
  // Start at a word boundary.
  while (from > 0 && from < n && !_isSpace(original.codeUnitAt(from - 1))) {
    from--;
  }
  var to = from + maxLength;
  if (matches.isNotEmpty && matches.first.end > to) to = matches.first.end;
  if (to >= n) {
    to = n;
  } else {
    // End at a word boundary.
    var t = to;
    while (t > from && !_isSpace(original.codeUnitAt(t))) {
      t--;
    }
    if (t > from) to = t;
    if (matches.isNotEmpty && to < matches.first.end) to = matches.first.end;
  }
  // Trim surrounding whitespace by moving the indexes.
  while (from < to && _isSpace(original.codeUnitAt(from))) {
    from++;
  }
  while (to > from && _isSpace(original.codeUnitAt(to - 1))) {
    to--;
  }

  final highlights = <(int, int)>[
    for (final m in matches)
      if (m.start >= from && m.end <= to) (m.start - from, m.end - from),
  ];
  return SearchSnippet(
    text: original.substring(from, to),
    highlights: highlights,
    truncatedStart: from > 0,
    truncatedEnd: to < n,
  );
}
