import 'package:bustan_al_rohban/core/content/content_issue.dart';
import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  final good = buildBook([
    saintJson(id: 'saint-a', sections: [
      sectionJson(id: 'sec-a-001', paragraphs: [paraJson(id: 'p-000001')]),
    ]),
    saintJson(id: 'saint-b', order: 2, sections: [
      sectionJson(id: 'sec-b-001', paragraphs: [paraJson(id: 'p-000002')]),
    ]),
  ]);

  InMemoryContentSource sourceOf(TestBook b) =>
      InMemoryContentSource({'manifest.json': b.manifestJson, ...b.files});

  test('loadManifest returns the entries in order', () async {
    final loader = ContentLoader(sourceOf(good));
    final manifest = await loader.loadManifest();
    expect(manifest.saints.map((s) => s.id), ['saint-a', 'saint-b']);
    expect(manifest.contentVersion, 1);
  });

  test('loadSaint loads one saint on demand', () async {
    final loader = ContentLoader(sourceOf(good));
    final manifest = await loader.loadManifest();
    final saint = await loader.loadSaint(manifest.saints[1]);
    expect(saint.id, 'saint-b');
    expect(saint.sections.single.paragraphs.single.id, 'p-000002');
  });

  test('loadBook validates and returns the whole book', () async {
    final loaded = await ContentLoader(sourceOf(good)).loadBook();
    expect(loaded.book.saints.length, 2);
    expect(loaded.book.saintById('saint-a')!.title, 'القديس');
    expect(loaded.warnings, isEmpty);
  });

  test('loadBook throws with the full report on invalid content', () async {
    final bad = buildBook([saintJson()], hashOverride: 'sha256:abc');
    expect(
      () => ContentLoader(sourceOf(bad)).loadBook(),
      throwsA(isA<ContentValidationException>().having(
        (e) => e.report.errors.map((i) => i.code),
        'codes',
        contains('content-hash-mismatch'),
      )),
    );
  });

  test('missing manifest is reported as a missing file', () async {
    final loader = ContentLoader(InMemoryContentSource({}));
    try {
      await loader.loadManifest();
      fail('expected ContentValidationException');
    } on ContentValidationException catch (e) {
      expect(e.report.errors.single.code, 'missing-file');
    }
  });

  test('missing saint file is reported', () async {
    final src = InMemoryContentSource({'manifest.json': good.manifestJson});
    expect(
      () => ContentLoader(src).loadBook(),
      throwsA(isA<ContentValidationException>()),
    );
  });

  test('release mode rejects fixture content', () async {
    final fixture = buildBook([saintJson()], fixture: true);
    final loader = ContentLoader(sourceOf(fixture));
    expect((await loader.loadBook()).book.manifest.fixture, isTrue);
    expect(
      () => loader.loadBook(allowFixture: false),
      throwsA(isA<ContentValidationException>().having(
        (e) => e.report.errors.map((i) => i.code),
        'codes',
        contains('fixture-in-release'),
      )),
    );
  });

  test('warnings do not block loading', () async {
    final b = buildBook([
      saintJson(sections: [
        sectionJson(paragraphs: [paraJson(page: null)]),
      ]),
    ]);
    final loaded = await ContentLoader(sourceOf(b)).loadBook();
    expect(loaded.warnings.map((i) => i.code), contains('page-unknown'));
  });
}
