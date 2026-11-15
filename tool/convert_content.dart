// Converts the owner's authoring text files into app JSON.
//
//   dart run tool/convert_content.dart <srcDir> <outDir> <registryFile> [contentVersion]
//
// <srcDir> holds book.txt and one NNN-name.txt per saint.
// <outDir> receives manifest.json and saints/<id>.json.
// <registryFile> is the paragraph ID registry (created if missing, updated).
// Nothing is written when there are errors; a Markdown report is printed.
import 'dart:convert';
import 'dart:io';

import 'package:bustan_al_rohban/core/content/authoring_converter.dart';
import 'package:bustan_al_rohban/core/content/id_registry.dart';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('Usage: dart run tool/convert_content.dart '
        '<srcDir> <outDir> <registryFile> [contentVersion]');
    exit(64);
  }
  final srcDir = Directory(args[0]);
  final outDir = Directory(args[1]);
  final registryFile = File(args[2]);
  final contentVersion = args.length > 3 ? int.parse(args[3]) : 1;

  final bookFile = File('${srcDir.path}/book.txt');
  if (!bookFile.existsSync()) {
    stderr.writeln('book.txt not found in ${srcDir.path}');
    exit(66);
  }
  final saintTexts = <String, String>{};
  for (final entity in srcDir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.txt') || name == 'book.txt') continue;
    saintTexts[name] = entity.readAsStringSync();
  }

  final registry = registryFile.existsSync()
      ? IdRegistry.fromJson(
          jsonDecode(registryFile.readAsStringSync()) as Map<String, dynamic>)
      : IdRegistry();

  final result = const AuthoringConverter().convertBook(
    bookText: bookFile.readAsStringSync(),
    saintTexts: saintTexts,
    registry: registry,
    contentVersion: contentVersion,
  );

  stdout.writeln(result.report.toMarkdown());
  if (!result.report.isValid) {
    stderr.writeln('Errors found: nothing was written.');
    exit(1);
  }

  const encoder = JsonEncoder.withIndent('  ');
  Directory('${outDir.path}/saints').createSync(recursive: true);
  File('${outDir.path}/manifest.json')
      .writeAsStringSync('${encoder.convert(result.manifest)}\n');
  result.saintFiles.forEach((file, json) {
    File('${outDir.path}/$file').writeAsStringSync('${encoder.convert(json)}\n');
  });
  registryFile.writeAsStringSync('${registry.toJsonString()}\n');
  stdout.writeln('Wrote ${result.saintFiles.length} saint file(s) to '
      '${outDir.path} and updated ${registryFile.path}.');
}
