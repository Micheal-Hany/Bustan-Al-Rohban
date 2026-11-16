import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import 'library_test_support.dart';

void main() {
  group('LibraryRepository', () {
    test('saints are returned in book order', () async {
      final repo = repoFor(probeFor(twoSaintBook()));
      final saints = await repo.saints();
      expect(saints.map((s) => s.id), ['saint-a', 'saint-b']);
    });

    test('manifest is read once and cached', () async {
      final source = probeFor(twoSaintBook());
      final repo = repoFor(source);
      await repo.manifest();
      await repo.saints();
      await repo.entry('saint-a');
      expect(source.reads['manifest.json'], 1);
    });

    test('entry returns null for an unknown id', () async {
      final repo = repoFor(probeFor(twoSaintBook()));
      expect(await repo.entry('nope'), isNull);
      expect((await repo.entry('saint-b'))!.title, 'القديس الثاني');
    });

    test('a saint file is loaded on demand and cached', () async {
      final source = probeFor(twoSaintBook());
      final repo = repoFor(source);
      await repo.manifest();
      expect(source.reads.keys.where((k) => k.startsWith('saints/')), isEmpty);

      final saint = await repo.saint('saint-a');
      expect(saint.sections.length, 2);
      await repo.saint('saint-a');
      expect(source.reads['saints/saint-a.json'], 1);
      expect(source.reads.containsKey('saints/saint-b.json'), isFalse);
    });

    test('unknown saint throws SaintNotFoundException', () async {
      final repo = repoFor(probeFor(twoSaintBook()));
      expect(
        () => repo.saint('missing'),
        throwsA(isA<SaintNotFoundException>()),
      );
    });

    test('a failed manifest load is not cached', () async {
      final book = twoSaintBook();
      final files = <String, String>{...book.files};
      final source = probeFor(book);
      // Break the manifest first.
      (source.inner as InMemoryContentSource).files.remove('manifest.json');
      final repo = repoFor(source);
      await expectLater(
        repo.manifest(),
        throwsA(isA<ContentValidationException>()),
      );
      // Fix it; the retry must succeed.
      (source.inner as InMemoryContentSource)
        ..files['manifest.json'] = book.manifestJson
        ..files.addAll(files);
      expect((await repo.manifest()).saints.length, 2);
    });

    test('a corrupt saint file surfaces a validation error', () async {
      final book = twoSaintBook();
      final source = probeFor(book);
      (source.inner as InMemoryContentSource).files['saints/saint-a.json'] =
          '{ not json';
      final repo = repoFor(source);
      await expectLater(
        repo.saint('saint-a'),
        throwsA(isA<ContentValidationException>()),
      );
    });
  });
}
