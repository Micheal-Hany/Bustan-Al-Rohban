// Release gate for content (Task 13). Run before building the store release:
//
//   dart run tool/release_content_check.dart <appDir> <backendDir> [pubspec]
//
// appDir is assets/content, backendDir is the folder the backend loads
// (its CORPUS_DIR), pubspec defaults to pubspec.yaml.
// Fails (exit 1) when:
//   - either manifest is FAKE (`fixture: true`) or contains "[تجريبي]" text;
//   - the app and backend differ in book id, content version, saint list or
//     paragraph ids;
//   - pubspec.yaml still bundles `assets/content_fixtures/`.
import 'dart:convert';
import 'dart:io';

/// Returns human-readable problems; empty means the gate passes.
List<String> checkReleaseContent({
  required String appDir,
  required String backendDir,
  required String pubspecPath,
}) {
  final problems = <String>[];

  Map<String, dynamic>? readJson(String path, String label) {
    final f = File(path);
    if (!f.existsSync()) {
      problems.add('$label: $path not found.');
      return null;
    }
    try {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      problems.add('$label: $path is not valid JSON ($e).');
      return null;
    }
  }

  final app = readJson('$appDir/manifest.json', 'app manifest');
  final back = readJson('$backendDir/manifest.json', 'backend manifest');

  for (final entry in {'app': app, 'backend': back}.entries) {
    final m = entry.value;
    if (m == null) continue;
    if (m['fixture'] == true) {
      problems.add('${entry.key}: manifest is FAKE fixture content.');
    }
    if (jsonEncode(m).contains('[تجريبي]')) {
      problems.add('${entry.key}: manifest still contains "[تجريبي]" text.');
    }
  }

  if (app != null && back != null) {
    if (app['bookId'] != back['bookId']) {
      problems.add('bookId differs: app ${app['bookId']} vs backend ${back['bookId']}.');
    }
    if (app['contentVersion'] != back['contentVersion']) {
      problems.add('contentVersion differs: app ${app['contentVersion']} '
          'vs backend ${back['contentVersion']}.');
    }
    List<String> ids(Map<String, dynamic> m) => [
          for (final s in (m['saints'] as List? ?? const []))
            (s as Map<String, dynamic>)['id'] as String,
        ];
    final appIds = ids(app);
    final backIds = ids(back);
    if (appIds.join(',') != backIds.join(',')) {
      problems.add('saint lists differ: app $appIds vs backend $backIds.');
    } else {
      for (final id in appIds) {
        final a = _paragraphIds('$appDir/saints/$id.json');
        final b = _paragraphIds('$backendDir/saints/$id.json');
        if (a == null || b == null) {
          problems.add('saint $id: file missing on '
              '${a == null ? 'app' : 'backend'} side.');
        } else if (a.join(',') != b.join(',')) {
          problems.add('saint $id: paragraph ids differ between app and backend.');
        }
      }
    }
  }

  final pubspec = File(pubspecPath);
  if (!pubspec.existsSync()) {
    problems.add('pubspec: $pubspecPath not found.');
  } else if (pubspec.readAsStringSync().contains('assets/content_fixtures')) {
    problems.add('pubspec.yaml still bundles assets/content_fixtures/ '
        '(debug-only invalid fixture).');
  }
  return problems;
}

List<String>? _paragraphIds(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final s in (j['sections'] as List? ?? const []))
      for (final p in ((s as Map<String, dynamic>)['paragraphs'] as List? ?? const []))
        (p as Map<String, dynamic>)['id'] as String,
  ];
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run tool/release_content_check.dart '
        '<appDir> <backendCorpusDir> [pubspec]');
    exit(64);
  }
  final problems = checkReleaseContent(
    appDir: args[0],
    backendDir: args[1],
    pubspecPath: args.length > 2 ? args[2] : 'pubspec.yaml',
  );
  if (problems.isEmpty) {
    stdout.writeln('Release content check: OK');
    return;
  }
  stdout.writeln('Release content check: FAILED');
  for (final p in problems) {
    stdout.writeln('- $p');
  }
  exit(1);
}
