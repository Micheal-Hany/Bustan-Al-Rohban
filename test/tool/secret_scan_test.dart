import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/secret_scan.dart';

// Fake values built at run time so this file itself holds no key-shaped text.
String _openAiLike() => 's${'k'}-${'a' * 24}';
String _googleLike() => 'AI${'za'}${'B' * 35}';

void main() {
  group('findSecrets', () {
    test('detects provider-style keys and key assignments', () {
      expect(findSecrets('x ${_openAiLike()} y'), isNotEmpty);
      expect(findSecrets('k=${_googleLike()}'), isNotEmpty);
      expect(findSecrets('OPENAI_API_KEY=abcdefgh12345'), isNotEmpty);
      expect(findSecrets('-----BEGIN PRIVATE KEY-----'), isNotEmpty);
      expect(findSecrets('Authorization: Bearer ${'t' * 30}'), isNotEmpty);
    });

    test('ignores ordinary text and names without values', () {
      expect(findSecrets('بستان الرهبان — نص عادي'), isEmpty);
      expect(findSecrets('const apiKeyHeader = "x-goog-api-key";'), isEmpty);
      expect(findSecrets('sk-short'), isEmpty);
      expect(findSecrets('OPENAI_API_KEY is set on the server'), isEmpty);
    });
  });

  group('scanPaths', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('scan_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('clean directory returns 0', () async {
      File('${dir.path}/a.txt').writeAsStringSync('hello');
      final sink = StringBuffer();
      expect(await scanPaths([dir.path], sink), 0);
    });

    test('finds a secret in text and in a binary file, without printing it',
        () async {
      File('${dir.path}/a.txt').writeAsStringSync('k ${_openAiLike()}');
      File('${dir.path}/b.bin')
          .writeAsBytesSync([0, 255, ..._googleLike().codeUnits, 0]);
      final sink = StringBuffer();
      expect(await scanPaths([dir.path], sink), 1);
      expect(sink.toString(), contains('a.txt'));
      expect(sink.toString(), contains('b.bin'));
      expect(sink.toString(), isNot(contains(_openAiLike())));
    });

    test('missing path returns 2', () async {
      expect(await scanPaths(['${dir.path}/nope'], StringBuffer()), 2);
    });
  });

  test('the app source, assets and config hold no provider secrets', () async {
    final sink = StringBuffer();
    final code = await scanPaths(
      ['lib', 'assets', 'android/app/src', 'pubspec.yaml'],
      sink,
    );
    expect(code, 0, reason: sink.toString());
  });
}
