import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every bundled font family must ship its licence text, and the licence
/// must be the SIL Open Font License (which allows embedding in an app).
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final fontFiles = RegExp(r'asset:\s*(assets/fonts/[^\s]+\.ttf)')
      .allMatches(pubspec)
      .map((m) => m.group(1)!)
      .toList();

  test('pubspec registers font files and each exists', () {
    expect(fontFiles, isNotEmpty);
    for (final f in fontFiles) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
  });

  for (final family in ['Amiri', 'Tajawal']) {
    test('$family: OFL 1.1 licence file is bundled', () {
      final file = File('assets/fonts/OFL-$family.txt');
      expect(file.existsSync(), isTrue);
      final text = file.readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(text, contains('Copyright'));
      expect(fontFiles.any((f) => f.contains('/$family-')), isTrue);
    });
  }

  test('every bundled .ttf belongs to a family with a licence file', () {
    for (final f in fontFiles) {
      final family = f.split('/').last.split('-').first;
      expect(File('assets/fonts/OFL-$family.txt').existsSync(), isTrue,
          reason: 'no licence for $f');
    }
  });

  test('assets/fonts has no unregistered font files', () {
    final onDisk = Directory('assets/fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/'))
        .where((p) => p.endsWith('.ttf'))
        .toSet();
    expect(onDisk, fontFiles.toSet());
  });
}
