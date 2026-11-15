enum IssueSeverity { error, warning }

/// One validation or conversion finding, with enough location detail for the
/// owner to find and fix it.
class ContentIssue {
  const ContentIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.file,
    this.path = '',
    this.line,
  });

  final IssueSeverity severity;

  /// Stable machine-readable code, e.g. `duplicate-id`.
  final String code;
  final String message;
  final String file;

  /// JSON path such as `sections[1].paragraphs[3].text` (empty for the file).
  final String path;

  /// 1-based line in an authoring text file, when known.
  final int? line;

  bool get isError => severity == IssueSeverity.error;

  String get location {
    final parts = <String>[file];
    if (line != null) parts.add('line $line');
    if (path.isNotEmpty) parts.add(path);
    return parts.join(' ');
  }

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}] $code $location: $message';
}

class ValidationReport {
  ValidationReport(Iterable<ContentIssue> issues)
      : issues = List.unmodifiable(issues);

  final List<ContentIssue> issues;

  List<ContentIssue> get errors =>
      issues.where((i) => i.severity == IssueSeverity.error).toList();

  List<ContentIssue> get warnings =>
      issues.where((i) => i.severity == IssueSeverity.warning).toList();

  bool get isValid => errors.isEmpty;

  /// Markdown report for the owner (used by the converter CLI and Task 13).
  String toMarkdown({String title = 'Content report'}) {
    final b = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln('- Errors: ${errors.length}')
      ..writeln('- Warnings: ${warnings.length}')
      ..writeln();
    void section(String heading, List<ContentIssue> list) {
      b.writeln('## $heading');
      if (list.isEmpty) {
        b.writeln('None.');
      } else {
        for (final i in list) {
          b.writeln('- `${i.code}` ${i.location}: ${i.message}');
        }
      }
      b.writeln();
    }

    section('Errors', errors);
    section('Warnings', warnings);
    return b.toString();
  }
}

class ContentValidationException implements Exception {
  ContentValidationException(this.report);

  final ValidationReport report;

  @override
  String toString() {
    final errors = report.errors;
    return 'ContentValidationException: ${errors.length} error(s)\n'
        '${errors.join('\n')}';
  }
}
