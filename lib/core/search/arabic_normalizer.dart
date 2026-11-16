/// Arabic-aware tokenizer and normalizer used only to build and query the
/// search index. It never changes displayed text: every token keeps the
/// [start, end) range it occupies in the ORIGINAL string.
///
/// Folding rules:
/// - diacritics (tashkeel, superscript alef, Quranic marks), tatweel and
///   zero-width / bidi marks are dropped;
/// - alef variants (أ إ آ ٱ) -> ا;  alef maqsura (ى) -> ي;  ta marbuta (ة) -> ه;
/// - Arabic-Indic and Persian digits -> ASCII digits;
/// - everything that is not a letter or digit separates tokens.
/// Hamza on waw/ya (ؤ ئ) is intentionally left unchanged.
class SearchToken {
  const SearchToken(this.value, this.start, this.end);

  /// Normalized form.
  final String value;

  /// Range in the original text.
  final int start;
  final int end;

  @override
  String toString() => 'SearchToken($value, $start-$end)';
}

const int _drop = 0;
const int _separator = -1;

/// Returns the folded code unit, [_drop] for ignorable characters, or
/// [_separator].
int _fold(int c) {
  if (c == 0x0640) return _drop; // tatweel
  if ((c >= 0x064B && c <= 0x065F) || c == 0x0670) return _drop;
  if ((c >= 0x06D6 && c <= 0x06DC) ||
      (c >= 0x06DF && c <= 0x06E4) ||
      c == 0x06E7 ||
      c == 0x06E8 ||
      (c >= 0x06EA && c <= 0x06ED)) {
    return _drop;
  }
  if (c == 0x200B ||
      c == 0x200C ||
      c == 0x200D ||
      c == 0x200E ||
      c == 0x200F ||
      c == 0x061C ||
      c == 0xFEFF ||
      c == 0x00AD) {
    return _drop;
  }
  switch (c) {
    case 0x0622: // آ
    case 0x0623: // أ
    case 0x0625: // إ
    case 0x0671: // ٱ
      return 0x0627; // ا
    case 0x0649: // ى
      return 0x064A; // ي
    case 0x0629: // ة
      return 0x0647; // ه
  }
  if (c >= 0x0660 && c <= 0x0669) return 0x30 + (c - 0x0660);
  if (c >= 0x06F0 && c <= 0x06F9) return 0x30 + (c - 0x06F0);
  if ((c >= 0x0621 && c <= 0x064A) ||
      (c >= 0x066E && c <= 0x06D3) ||
      (c >= 0x06FA && c <= 0x06FF)) {
    return c;
  }
  if (c >= 0x30 && c <= 0x39) return c;
  if (c >= 0x41 && c <= 0x5A) return c + 0x20; // A-Z -> a-z
  if (c >= 0x61 && c <= 0x7A) return c;
  if (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7) return c;
  return _separator;
}

/// Splits [text] into normalized tokens with their original ranges.
List<SearchToken> tokenizeArabic(String text) {
  final tokens = <SearchToken>[];
  final buf = StringBuffer();
  var start = -1;
  var end = -1;

  void flush() {
    if (start >= 0 && buf.isNotEmpty) {
      tokens.add(SearchToken(buf.toString(), start, end));
    }
    buf.clear();
    start = -1;
    end = -1;
  }

  for (var i = 0; i < text.length; i++) {
    final f = _fold(text.codeUnitAt(i));
    if (f == _separator) {
      flush();
    } else if (f == _drop) {
      if (start >= 0) end = i + 1; // diacritics stay inside the token range
    } else {
      if (start < 0) start = i;
      buf.writeCharCode(f);
      end = i + 1;
    }
  }
  flush();
  return tokens;
}

/// Normalized text: tokens joined by single spaces.
String normalizeArabic(String text) =>
    tokenizeArabic(text).map((t) => t.value).join(' ');

/// Normalized query tokens (duplicates removed, order kept).
List<String> queryTokens(String query) {
  final seen = <String>{};
  return [
    for (final t in tokenizeArabic(query))
      if (seen.add(t.value)) t.value,
  ];
}
