// Content report for the owner (Task 13).
//
//   dart run tool/content_report.dart <contentDir> [--release] [--out report.md]
//
// <contentDir> holds manifest.json and saints/*.json (the converter output,
// for example assets/content). Runs the full validator plus the extraction
// quality checks, prints a Markdown report, and exits 1 if there are errors.
// --release also rejects FAKE (fixture) content.
import 'dart:io';

import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/core/content/content_quality.dart';
import 'package:bustan_al_rohban/core/content/content_source.dart';

class _DiskSource implements ContentSource {
  _DiskSource(this.root);
  final String root;

  @override
  Future<String> readString(String relativePath) =>
      File('$root/$relativePath').readAsString();
}

Future<void> main(List<String> args) async {
  final release = args.contains('--release');
  final outIndex = args.indexOf('--out');
  final outPath = outIndex >= 0 && outIndex + 1 < args.length
      ? args[outIndex + 1]
      : null;
  final positional = [
    for (var i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') && (i == 0 || args[i - 1] != '--out'))
        args[i],
  ];
  if (positional.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/content_report.dart <contentDir> [--release] [--out file]');
    exit(64);
  }

  final buffer = StringBuffer();
  var exitCode = 0;
  try {
    final loaded = await ContentLoader(_DiskSource(positional.first))
        .loadBook(allowFixture: !release);
    buffer
      ..writeln('# Content validation: OK')
      ..writeln()
      ..writeln('- Content version: ${loaded.book.manifest.contentVersion}')
      ..writeln('- Fixture (FAKE) content: ${loaded.book.manifest.fixture}')
      ..writeln('- Validator warnings: ${loaded.warnings.length}')
      ..writeln();
    for (final w in loaded.warnings) {
      buffer.writeln('- `${w.code}` ${w.location}: ${w.message}');
    }
    buffer
      ..writeln()
      ..write(const ContentQualityChecker().check(loaded.book).toMarkdown());
  } on ContentValidationException catch (e) {
    buffer.write(e.report.toMarkdown(title: 'Content validation: FAILED'));
    exitCode = 1;
  }

  final text = buffer.toString();
  if (outPath != null) File(outPath).writeAsStringSync(text);
  stdout.write(text);
  exit(exitCode);
}
