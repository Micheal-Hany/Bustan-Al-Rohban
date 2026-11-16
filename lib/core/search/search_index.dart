import 'dart:math' as math;

import '../content/content_models.dart';
import 'arabic_normalizer.dart';

/// A searchable paragraph. Holds references only: displayed text always comes
/// from the original content, never from the index.
class IndexedParagraph {
  const IndexedParagraph({
    required this.saintId,
    required this.sectionId,
    required this.paragraphId,
    required this.page,
    required this.isHeading,
  });

  final String saintId;
  final String sectionId;
  final String paragraphId;
  final int? page;
  final bool isHeading;
}

class SearchHit {
  const SearchHit(this.paragraph, this.score);

  final IndexedParagraph paragraph;
  final double score;
}

class SearchResults {
  const SearchResults({
    required this.tokens,
    required this.total,
    required this.hits,
  });

  /// Normalized query tokens.
  final List<String> tokens;

  /// Number of matching paragraphs (hits may be capped by `limit`).
  final int total;
  final List<SearchHit> hits;

  static const empty = SearchResults(tokens: [], total: 0, hits: []);
}

class _Posting {
  _Posting(this.doc, this.positions);

  final int doc;
  final List<int> positions;
}

/// In-memory inverted index over normalized paragraph tokens.
///
/// Matching: every query token must match the paragraph (AND). A token
/// matches a term exactly or as a prefix (prefix needs 2+ characters).
/// Ranking: BM25 per token (exact matches weigh more than prefix matches),
/// a boost for phrase order/adjacency and for headings. Ties keep book order.
class SearchIndex {
  static const _k1 = 1.2;
  static const _b = 0.75;
  static const _prefixWeight = 0.6;
  static const _phraseBoost = 1.5;
  static const _headingBoost = 1.1;
  static const _maxPrefixTerms = 200;

  final List<IndexedParagraph> _docs = [];
  final List<int> _docLength = [];
  final Map<String, List<_Posting>> _postings = {};
  List<String> _sortedTerms = const [];
  double _avgLength = 1;
  bool _finalized = false;

  int get documentCount => _docs.length;
  int get termCount => _postings.length;
  bool get isFinalized => _finalized;

  /// Adds every paragraph of [saint], in book order. Call [finalize] after the
  /// last saint.
  void addSaint(Saint saint) {
    for (final section in saint.sections) {
      for (final p in section.paragraphs) {
        final doc = _docs.length;
        final tokens = tokenizeArabic(p.text);
        _docs.add(IndexedParagraph(
          saintId: saint.id,
          sectionId: section.id,
          paragraphId: p.id,
          page: p.page,
          isHeading: p.kind == ParagraphKind.heading,
        ));
        _docLength.add(tokens.length);
        final byTerm = <String, List<int>>{};
        for (var i = 0; i < tokens.length; i++) {
          byTerm.putIfAbsent(tokens[i].value, () => []).add(i);
        }
        byTerm.forEach((term, positions) {
          _postings.putIfAbsent(term, () => []).add(_Posting(doc, positions));
        });
      }
    }
    _finalized = false;
  }

  void finalize() {
    _sortedTerms = _postings.keys.toList()..sort();
    final total = _docLength.fold<int>(0, (a, b) => a + b);
    _avgLength = _docs.isEmpty ? 1 : math.max(1.0, total / _docs.length);
    _finalized = true;
  }

  /// First index in [_sortedTerms] that is >= [value].
  int _lowerBound(String value) {
    var lo = 0;
    var hi = _sortedTerms.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_sortedTerms[mid].compareTo(value) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Terms matching [token]: (term, weight).
  List<(String, double)> _matchTerms(String token) {
    final result = <(String, double)>[];
    if (_postings.containsKey(token)) result.add((token, 1.0));
    if (token.length >= 2) {
      var i = _lowerBound(token);
      var added = 0;
      while (i < _sortedTerms.length &&
          _sortedTerms[i].startsWith(token) &&
          added < _maxPrefixTerms) {
        if (_sortedTerms[i] != token) {
          result.add((_sortedTerms[i], _prefixWeight));
          added++;
        }
        i++;
      }
    }
    return result;
  }

  double _bm25(int tf, int docLength, int df, double weight) {
    final n = _docs.length;
    final idf = math.log(1 + (n - df + 0.5) / (df + 0.5));
    final norm = tf * (_k1 + 1) /
        (tf + _k1 * (1 - _b + _b * docLength / _avgLength));
    return weight * idf * norm;
  }

  SearchResults search(String query, {int limit = 100}) {
    assert(_finalized, 'call finalize() after adding content');
    final tokens = queryTokens(query);
    if (tokens.isEmpty || _docs.isEmpty) {
      return SearchResults(tokens: tokens, total: 0, hits: const []);
    }

    // Per token: doc -> (best score, matched positions).
    final perToken = <Map<int, (double, Set<int>)>>[];
    for (final token in tokens) {
      final matches = <int, (double, Set<int>)>{};
      for (final (term, weight) in _matchTerms(token)) {
        final postings = _postings[term]!;
        final df = postings.length;
        for (final p in postings) {
          final s = _bm25(p.positions.length, _docLength[p.doc], df, weight);
          final prev = matches[p.doc];
          if (prev == null) {
            matches[p.doc] = (s, {...p.positions});
          } else {
            prev.$2.addAll(p.positions);
            if (s > prev.$1) matches[p.doc] = (s, prev.$2);
          }
        }
      }
      if (matches.isEmpty) {
        return SearchResults(tokens: tokens, total: 0, hits: const []);
      }
      perToken.add(matches);
    }

    // AND: start from the smallest candidate set.
    final smallest =
        perToken.reduce((a, b) => a.length <= b.length ? a : b);
    final candidates = smallest.keys
        .where((d) => perToken.every((m) => m.containsKey(d)))
        .toList();

    final scored = <(int, double)>[];
    for (final d in candidates) {
      var score = 0.0;
      for (final m in perToken) {
        score += m[d]!.$1;
      }
      if (tokens.length > 1 && _hasPhrase(perToken, d)) {
        score *= _phraseBoost;
      }
      if (_docs[d].isHeading) score *= _headingBoost;
      scored.add((d, score));
    }

    // Stable ordering: score desc, then book order (doc index).
    scored.sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    final top = scored.length > limit ? scored.sublist(0, limit) : scored;
    return SearchResults(
      tokens: tokens,
      total: scored.length,
      hits: [for (final (d, s) in top) SearchHit(_docs[d], s)],
    );
  }

  bool _hasPhrase(List<Map<int, (double, Set<int>)>> perToken, int doc) {
    for (final start in perToken.first[doc]!.$2) {
      var ok = true;
      for (var i = 1; i < perToken.length; i++) {
        if (!perToken[i][doc]!.$2.contains(start + i)) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }
}
