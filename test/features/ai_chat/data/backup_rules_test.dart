import 'dart:io';

import 'package:bustan_al_rohban/features/ai_chat/data/chat_connection.dart';
import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res/xml';

String _read(String path) => File(path).readAsStringSync();

/// All `<exclude ...>` entries inside [section] ([tag] element) as
/// (domain, path).
List<({String domain, String path})> _excludes(String xml, String tag) {
  final block =
      RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml)?.group(1) ?? '';
  return [
    for (final m in RegExp(r'<exclude\s+([^>]*?)/>').allMatches(block))
      (
        domain: RegExp(r'domain="([^"]*)"').firstMatch(m.group(1)!)!.group(1)!,
        path: RegExp(r'path="([^"]*)"').firstMatch(m.group(1)!)!.group(1)!,
      ),
  ];
}

void main() {
  const chatExclude = (domain: 'file', path: '$chatDbFolder/');

  test('the chat database lives in the excluded folder', () {
    expect(chatDbFolder, 'chat');
    expect(chatDbFileName, endsWith('.sqlite'));
  });

  test('backup_rules.xml (Android 11-) excludes the chat folder', () {
    final xml = _read('$_res/backup_rules.xml');
    expect(_excludes(xml, 'full-backup-content'), contains(chatExclude));
  });

  test('data_extraction_rules.xml (Android 12+) excludes it from cloud backup '
      'and device transfer', () {
    final xml = _read('$_res/data_extraction_rules.xml');
    expect(_excludes(xml, 'cloud-backup'), contains(chatExclude));
    expect(_excludes(xml, 'device-transfer'), contains(chatExclude));
  });

  test('the manifest points at both rule files and does not disable them', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    expect(manifest, isNot(contains('android:allowBackup="false"')));
  });

  test('the bookmarks/progress database is NOT in the excluded folder', () {
    // bustan.sqlite sits directly in the files directory, not in chat/.
    final conn = _read('lib/core/db/connection.dart');
    expect(conn, contains("'bustan.sqlite'"));
    expect(conn, isNot(contains(chatDbFolder)));
  });
}
