import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_content_check.dart';

void _write(String path, Object json) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(json));
}

void _corpus(
  String dir, {
  bool fixture = false,
  int version = 3,
  String title = 'بستان الرهبان',
  List<String> paragraphs = const ['p-1', 'p-2'],
}) {
  _write('$dir/manifest.json', {
    'bookId': 'bustan',
    'contentVersion': version,
    'fixture': fixture,
    'title': title,
    'saints': [
      {'id': 's1', 'title': 'قديس'},
    ],
  });
  _write('$dir/saints/s1.json', {
    'id': 's1',
    'sections': [
      {
        'id': 'sec',
        'paragraphs': [
          for (final p in paragraphs) {'id': p},
        ],
      },
    ],
  });
}

void main() {
  late Directory root;
  late String app;
  late String back;
  late String pubspec;

  setUp(() {
    root = Directory.systemTemp.createTempSync('relcheck_');
    app = '${root.path}/app';
    back = '${root.path}/back';
    pubspec = '${root.path}/pubspec.yaml';
    File(pubspec).writeAsStringSync('flutter:\n  assets:\n    - assets/content/\n');
  });
  tearDown(() => root.deleteSync(recursive: true));

  List<String> run() =>
      checkReleaseContent(appDir: app, backendDir: back, pubspecPath: pubspec);

  test('matching real content passes', () {
    _corpus(app);
    _corpus(back);
    expect(run(), isEmpty);
  });

  test('fixture content on either side fails', () {
    _corpus(app, fixture: true);
    _corpus(back);
    expect(run().join('\n'), contains('app: manifest is FAKE'));
    _corpus(app);
    _corpus(back, fixture: true);
    expect(run().join('\n'), contains('backend: manifest is FAKE'));
  });

  test('leftover [تجريبي] label fails', () {
    _corpus(app, title: '[تجريبي] عنوان');
    _corpus(back);
    expect(run().join('\n'), contains('[تجريبي]'));
  });

  test('different content versions fail', () {
    _corpus(app, version: 4);
    _corpus(back, version: 3);
    expect(run().join('\n'), contains('contentVersion differs'));
  });

  test('different paragraph ids fail', () {
    _corpus(app, paragraphs: ['p-1', 'p-2']);
    _corpus(back, paragraphs: ['p-1', 'p-9']);
    expect(run().join('\n'), contains('paragraph ids differ'));
  });

  test('missing backend corpus is reported, not thrown', () {
    _corpus(app);
    expect(run().join('\n'), contains('backend manifest'));
  });

  test('pubspec bundling the invalid fixture fails', () {
    _corpus(app);
    _corpus(back);
    File(pubspec).writeAsStringSync('    - assets/content_fixtures/invalid/\n');
    expect(run().join('\n'), contains('content_fixtures'));
  });
}
