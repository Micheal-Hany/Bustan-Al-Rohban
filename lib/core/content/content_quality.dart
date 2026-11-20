import 'content_issue.dart';
import 'content_models.dart';

/// Per-saint numbers for the content report (and the size budget decision).
class SaintStats {
  const SaintStats({
    required this.id,
    required this.title,
    required this.sections,
    required this.paragraphs,
    required this.characters,
    required this.words,
    required this.pagesMissing,
    required this.firstPage,
    required this.lastPage,
  });

  final String id;
  final String title;
  final int sections;
  final int paragraphs;
  final int characters;
  final int words;
  final int pagesMissing;
  final int? firstPage;
  final int? lastPage;
}

class QualityReport {
  QualityReport(this.issues, this.stats);

  /// All findings are warnings: the owner decides what to correct.
  final List<ContentIssue> issues;
  final List<SaintStats> stats;

  int get totalParagraphs => stats.fold(0, (a, s) => a + s.paragraphs);
  int get totalCharacters => stats.fold(0, (a, s) => a + s.characters);
  int get totalWords => stats.fold(0, (a, s) => a + s.words);

  Map<String, int> get countsByCode {
    final m = <String, int>{};
    for (final i in issues) {
      m[i.code] = (m[i.code] ?? 0) + 1;
    }
    return m;
  }

  /// Markdown for the owner. [maxPerCode] keeps a bad extraction (thousands
  /// of the same finding) readable; the totals still show the full count.
  String toMarkdown({int maxPerCode = 25}) {
    final b = StringBuffer()
      ..writeln('# Content quality report')
      ..writeln()
      ..writeln('- Saints: ${stats.length}')
      ..writeln('- Paragraphs: $totalParagraphs')
      ..writeln('- Words: $totalWords, characters: $totalCharacters')
      ..writeln('- Findings: ${issues.length} (warnings; the owner decides)')
      ..writeln()
      ..writeln('## Per saint')
      ..writeln()
      ..writeln('| Saint | Sections | Paragraphs | Words | Pages | No page |')
      ..writeln('|---|---|---|---|---|---|');
    for (final s in stats) {
      final pages = s.firstPage == null ? '-' : '${s.firstPage}-${s.lastPage}';
      b.writeln('| ${s.title} (`${s.id}`) | ${s.sections} | ${s.paragraphs} '
          '| ${s.words} | $pages | ${s.pagesMissing} |');
    }
    b
      ..writeln()
      ..writeln('## Findings by kind')
      ..writeln();
    if (issues.isEmpty) b.writeln('None.');
    final byCode = <String, List<ContentIssue>>{};
    for (final i in issues) {
      byCode.putIfAbsent(i.code, () => []).add(i);
    }
    for (final e in byCode.entries) {
      b.writeln('### `${e.key}` (${e.value.length})');
      for (final i in e.value.take(maxPerCode)) {
        b.writeln('- ${i.location}: ${i.message}');
      }
      if (e.value.length > maxPerCode) {
        b.writeln('- … and ${e.value.length - maxPerCode} more');
      }
      b.writeln();
    }
    return b.toString();
  }
}

/// Looks for problems typical of text extracted from a PDF. It only reads
/// the text; nothing is changed or corrected automatically.
class ContentQualityChecker {
  const ContentQualityChecker({
    this.longParagraphChars = 4000,
    this.pageJumpWarning = 25,
    this.minDuplicateChars = 30,
  });

  final int longParagraphChars;
  final int pageJumpWarning;
  final int minDuplicateChars;

  static final _presentationForms =
      RegExp('[\u{FB50}-\u{FDFF}\u{FE70}-\u{FEFF}]');
  static final _zeroWidth = RegExp('[​-‏‪-‮⁦-⁩﻿]');
  static final _control = RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]');
  static final _privateUse = RegExp('[-]');
  static final _replacement = RegExp('�');
  static final _latinLetters = RegExp('[A-Za-z]{2,}');
  static final _mojibake = RegExp('[ØÙÚÛÃÂ][\u0080-¿]');
  static final _tatweelRun = RegExp('ـ{3,}');
  static final _punctRun = RegExp(r'([.،؛:!؟\-_*])\1{3,}');
  static final _spaceRun = RegExp(r' {3,}');
  static final _arabic = RegExp('[؀-ۿ]');

  QualityReport check(ContentBook book) {
    final issues = <ContentIssue>[];
    final stats = <SaintStats>[];
    final seenText = <String, String>{};

    for (final entry in book.manifest.saints) {
      final saint = book.saints.firstWhere((s) => s.id == entry.id);
      final file = entry.file;
      var chars = 0;
      var words = 0;
      var missing = 0;
      int? first;
      int? last;
      int? prevPage;

      for (var si = 0; si < saint.sections.length; si++) {
        final section = saint.sections[si];
        for (var pi = 0; pi < section.paragraphs.length; pi++) {
          final p = section.paragraphs[pi];
          final path = 'sections[$si].paragraphs[$pi]';
          void warn(String code, String message) => issues.add(ContentIssue(
                severity: IssueSeverity.warning,
                code: code,
                file: file,
                path: path,
                message: '${p.id}: $message',
              ));
          final text = p.text;
          final trimmed = text.trim();
          chars += text.length;
          words += trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;

          if (trimmed.isEmpty) {
            warn('empty-paragraph', 'the text is empty.');
            continue;
          }
          final excerpt =
              trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed;
          if (_replacement.hasMatch(text)) {
            warn('replacement-char', 'contains the "�" character: "$excerpt"');
          }
          if (_mojibake.hasMatch(text)) {
            warn('mojibake', 'looks like wrongly decoded text: "$excerpt"');
          }
          if (_presentationForms.hasMatch(text)) {
            warn('presentation-forms',
                'contains Arabic presentation-form letters (common in PDF copy): "$excerpt"');
          }
          if (_zeroWidth.hasMatch(text)) {
            warn('invisible-chars', 'contains zero-width or direction-control characters.');
          }
          if (_control.hasMatch(text)) {
            warn('control-chars', 'contains control characters.');
          }
          if (_privateUse.hasMatch(text)) {
            warn('private-use-chars', 'contains private-use characters (font-specific glyphs).');
          }
          if (_tatweelRun.hasMatch(text)) {
            warn('tatweel-run', 'has a run of 3+ tatweel characters: "$excerpt"');
          }
          if (_punctRun.hasMatch(text)) {
            warn('punctuation-run', 'has a long run of repeated punctuation: "$excerpt"');
          }
          if (_spaceRun.hasMatch(text)) {
            warn('space-run', 'has 3+ consecutive spaces.');
          }
          if (_latinLetters.hasMatch(text) && _arabic.hasMatch(text)) {
            warn('latin-in-arabic', 'mixes Latin letters into Arabic text: "$excerpt"');
          }
          if (p.kind == ParagraphKind.body && trimmed.length < 3) {
            warn('very-short', 'body paragraph is only "$trimmed".');
          }
          if (text.length > longParagraphChars) {
            warn('very-long',
                '${text.length} characters; two paragraphs may have merged.');
          }
          if (p.kind == ParagraphKind.body &&
              trimmed.length >= minDuplicateChars) {
            final other = seenText[trimmed];
            if (other != null) {
              warn('duplicate-text', 'same text as $other.');
            } else {
              seenText[trimmed] = p.id;
            }
          }

          final page = p.page;
          if (page == null) {
            missing++;
          } else {
            first ??= page;
            last = page;
            if (prevPage != null && page < prevPage) {
              warn('page-goes-back', 'page $page follows page $prevPage.');
            } else if (prevPage != null && page - prevPage > pageJumpWarning) {
              warn('page-jump', 'page jumps from $prevPage to $page.');
            }
            prevPage = page;
          }
        }
      }
      if (missing > 0) {
        issues.add(ContentIssue(
          severity: IssueSeverity.warning,
          code: 'pages-missing',
          file: file,
          message: '$missing paragraph(s) have no page number.',
        ));
      }
      stats.add(SaintStats(
        id: saint.id,
        title: saint.title,
        sections: saint.sections.length,
        paragraphs: saint.paragraphCount,
        characters: chars,
        words: words,
        pagesMissing: missing,
        firstPage: first,
        lastPage: last,
      ));
    }
    return QualityReport(issues, stats);
  }
}
