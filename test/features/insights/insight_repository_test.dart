import 'dart:io';

import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/features/insights/domain/insight.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import 'insights_test_support.dart';

void main() {
  final file = insightsFile([
    insightJson(id: 'ok', status: 'approved'),
    insightJson(id: 'dr', status: 'draft', reviewedBy: null),
    insightJson(id: 'rj', status: 'rejected', reviewedBy: null),
    insightJson(id: 'other', sectionId: 'sec-a-002', support: ['p-000003']),
  ]);

  test('release mode shows only approved insights of the section', () async {
    final t = insightRepo(file);
    final saint = await t.repo.saint('saint-a');
    final list = await t.repo.insightsFor(saint, 'sec-a-001');
    expect(list.map((i) => i.id), ['ok']);
  });

  test('debug mode also shows drafts, never rejected', () async {
    final t = insightRepo(file, showUnapproved: true);
    final saint = await t.repo.saint('saint-a');
    final list = await t.repo.insightsFor(saint, 'sec-a-001');
    expect(list.map((i) => i.id), ['ok', 'dr']);
  });

  test('insights are filtered by section', () async {
    final t = insightRepo(file);
    final saint = await t.repo.saint('saint-a');
    expect((await t.repo.insightsFor(saint, 'sec-a-002')).map((i) => i.id),
        ['other']);
  });

  test('a saint without an insights file has no insights and no issues',
      () async {
    final t = insightRepo(null);
    final saint = await t.repo.saint('saint-a');
    expect(await t.repo.insightsFor(saint, 'sec-a-001'), isEmpty);
    expect(t.repo.insightIssues, isEmpty);
  });

  test('an invalid file shows nothing and records the issues', () async {
    final bad = insightsFile([
      insightJson(id: 'ok'),
      insightJson(id: 'bad', sectionId: 'nope'),
    ]);
    final t = insightRepo(bad);
    final saint = await t.repo.saint('saint-a');
    expect(await t.repo.insightsFor(saint, 'sec-a-001'), isEmpty);
    expect(t.repo.insightIssues.map((i) => i.code),
        contains('insight-missing-section'));
  });

  test('the insights file is read once (cached)', () async {
    final t = insightRepo(file);
    final saint = await t.repo.saint('saint-a');
    await t.repo.insightsFor(saint, 'sec-a-001');
    await t.repo.insightsFor(saint, 'sec-a-002');
    expect(t.source.reads['insights/saint-a.insights.json'], 1);
  });

  test('the shipped FAKE insights file is valid against its saint', () async {
    final loader = ContentLoader(DiskContentSource('assets/content'));
    final repo = LibraryRepository(loader, showUnapproved: true);
    final saint = await repo.saint('saint-fake-one');
    final text =
        File('assets/content/insights/saint-fake-one.insights.json')
            .readAsStringSync();
    final r = parseInsights(text, saint);
    expect(r.issues, isEmpty);
    expect(r.insights, hasLength(3));
    expect(r.insights.every((i) => i.fixture), isTrue);
    // Release rule on the shipped sample: one approved insight in section 1.
    final release = LibraryRepository(loader, showUnapproved: false);
    expect(
        (await release.insightsFor(saint, 'sec-fake-one-001'))
            .map((i) => i.id),
        ['ins-fake-one-001']);
    expect(await release.insightsFor(saint, 'sec-fake-one-002'), isEmpty);
  });
}
