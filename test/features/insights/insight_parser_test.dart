import 'package:bustan_al_rohban/features/insights/domain/insight.dart';
import 'package:flutter_test/flutter_test.dart';

import 'insights_test_support.dart';

Set<String> _codes(InsightParseResult r) => {for (final i in r.issues) i.code};

void main() {
  final saint = saintA();

  group('parseInsights', () {
    test('parses a valid insight with every field', () {
      final r = parseInsights(insightsFile([insightJson()]), saint);
      expect(r.issues, isEmpty);
      final i = r.insights.single;
      expect(i.id, 'ins-a-001');
      expect(i.sectionId, 'sec-a-001');
      expect(i.keyPoints, ['نقطة ١', 'نقطة ٢']);
      expect(i.spiritualLessons, ['درس']);
      expect(i.keywords, ['كلمة']);
      expect(i.supportingParagraphIds, ['p-000001', 'p-000002']);
      expect(i.origin, InsightOrigin.aiDraft);
      expect(i.reviewStatus, ReviewStatus.approved);
      expect(i.isApproved, isTrue);
    });

    test('optional lists may be omitted', () {
      final m = insightJson()
        ..remove('keyPoints')
        ..remove('spiritualLessons')
        ..remove('keywords');
      final r = parseInsights(insightsFile([m]), saint);
      expect(r.issues, isEmpty);
      expect(r.insights.single.keyPoints, isEmpty);
    });

    test('human origin and draft status', () {
      final r = parseInsights(
          insightsFile([insightJson(origin: 'human', status: 'draft')]),
          saint);
      expect(r.insights.single.origin, InsightOrigin.human);
      expect(r.insights.single.isApproved, isFalse);
    });

    test('a missing section is an error and the insight is dropped', () {
      final r = parseInsights(
          insightsFile([insightJson(sectionId: 'sec-zzz')]), saint);
      expect(_codes(r), contains('insight-missing-section'));
      expect(r.insights, isEmpty);
      expect(r.hasErrors, isTrue);
    });

    test('a missing supporting paragraph is an error', () {
      final r = parseInsights(
          insightsFile([insightJson(support: ['p-000001', 'p-999999'])]),
          saint);
      expect(_codes(r), contains('insight-missing-paragraph'));
      expect(r.insights, isEmpty);
    });

    test('a paragraph from another section of the same saint is valid', () {
      final r = parseInsights(
          insightsFile([insightJson(support: ['p-000003'])]), saint);
      expect(r.issues, isEmpty);
    });

    test('supportingParagraphIds is required', () {
      final m = insightJson()..remove('supportingParagraphIds');
      final r = parseInsights(insightsFile([m]), saint);
      expect(_codes(r), contains('missing-field'));
    });

    test('duplicate ids are an error', () {
      final r = parseInsights(
          insightsFile([insightJson(), insightJson()]), saint);
      expect(_codes(r), contains('duplicate-id'));
      expect(r.insights, hasLength(1));
    });

    test('bad origin and bad review status are errors', () {
      final r = parseInsights(
          insightsFile([insightJson(origin: 'robot', status: 'maybe')]),
          saint);
      expect(_codes(r), containsAll(['bad-origin', 'bad-review-status']));
    });

    test('an approved insight must name a reviewer', () {
      final r = parseInsights(
          insightsFile([insightJson(reviewedBy: null)]), saint);
      expect(_codes(r), contains('approved-without-reviewer'));
    });

    test('an empty summary is an error', () {
      final r =
          parseInsights(insightsFile([insightJson(summary: '  ')]), saint);
      expect(_codes(r), contains('missing-field'));
    });

    test('one bad insight does not drop the good ones', () {
      final r = parseInsights(
          insightsFile([
            insightJson(),
            insightJson(id: 'ins-a-002', sectionId: 'nope'),
          ]),
          saint);
      expect(r.insights.map((i) => i.id), ['ins-a-001']);
      expect(r.hasErrors, isTrue);
    });

    test('file-level problems', () {
      expect(_codes(parseInsights('not json', saint)), {'invalid-json'});
      expect(_codes(parseInsights('[]', saint)), {'wrong-type'});
      expect(
          _codes(parseInsights(
              insightsFile([insightJson()], saintId: 'saint-b'), saint)),
          {'id-mismatch'});
      expect(
          _codes(parseInsights(
              '{"schemaVersion":2,"saintId":"saint-a","insights":[]}', saint)),
          {'unsupported-schema'});
      expect(
          _codes(parseInsights(
              '{"schemaVersion":1,"saintId":"saint-a"}', saint)),
          {'missing-field'});
    });
  });

  group('visibleInsights (release rule)', () {
    final all = parseInsights(
      insightsFile([
        insightJson(id: 'a', status: 'approved'),
        insightJson(id: 'd', status: 'draft'),
        insightJson(id: 'r', status: 'rejected'),
      ]),
      saint,
    ).insights;

    test('release: only approved', () {
      final v = visibleInsights(all, showUnapproved: false);
      expect(v.map((i) => i.id), ['a']);
    });

    test('debug: approved and drafts, never rejected', () {
      final v = visibleInsights(all, showUnapproved: true);
      expect(v.map((i) => i.id), ['a', 'd']);
    });
  });
}
