import 'package:bustan_al_rohban/app/app.dart';
import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/app/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'insights_test_support.dart';

const _sectionPath = '/library/book/saints/saint-a/sections/sec-a-001';

Future<void> _open(
  WidgetTester tester,
  String? insightsText, {
  bool showUnapproved = false,
  String path = _sectionPath,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final t = insightRepo(insightsText, showUnapproved: showUnapproved);
  await tester.pumpWidget(BustanApp(libraryRepository: t.repo));
  await tester.pumpAndSettle();
  final ctx = tester.element(find.byKey(const Key('home-screen')));
  GoRouter.of(ctx).push(path);
  await tester.pumpAndSettle();
}

void main() {
  final approved = insightsFile([insightJson()]);

  testWidgets('no insights: the reader has no insights button',
      (tester) async {
    await _open(tester, null);
    expect(find.byKey(const Key('reader-screen')), findsOneWidget);
    expect(find.byKey(const Key('reader-insights-button')), findsNothing);
  });

  testWidgets('only an unapproved draft in release: no button', (tester) async {
    await _open(tester,
        insightsFile([insightJson(status: 'draft', reviewedBy: null)]));
    expect(find.byKey(const Key('reader-insights-button')), findsNothing);
  });

  testWidgets('the button opens the insights with every part',
      (tester) async {
    await _open(tester, approved);
    await tester.tap(find.byKey(const Key('reader-insights-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insights-screen')), findsOneWidget);
    expect(find.byKey(const Key('insight-ins-a-001')), findsOneWidget);
    expect(find.text(AppStrings.insightsLabel), findsOneWidget);
    expect(find.byIcon(AppIcons.insights), findsWidgets);
    expect(find.text('ملخص'), findsOneWidget);
    expect(find.text('• نقطة ١'), findsOneWidget);
    expect(find.text('• درس'), findsOneWidget);
    expect(find.text('كلمة'), findsOneWidget);
    expect(find.text(AppStrings.insightOriginAi), findsOneWidget);
    expect(find.text(AppStrings.insightApproved), findsOneWidget);
    expect(find.text(AppStrings.insightNotApproved), findsNothing);
  });

  testWidgets('insights are not book text (no paragraph keys, own label)',
      (tester) async {
    await _open(tester, approved);
    await tester.tap(find.byKey(const Key('reader-insights-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('para-p-000001')), findsNothing);
    expect(find.byKey(const Key('reader-list')), findsNothing);
  });

  testWidgets('a source chip jumps to that paragraph in the text',
      (tester) async {
    await _open(tester, approved);
    await tester.tap(find.byKey(const Key('reader-insights-button')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('insight-source-ins-a-001-p-000002')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-screen')), findsOneWidget);
    expect(find.byKey(const Key('para-p-000002')), findsOneWidget);
  });

  testWidgets('back to text returns to the reader', (tester) async {
    await _open(tester, approved);
    await tester.tap(find.byKey(const Key('reader-insights-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('insights-back-to-text')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-screen')), findsOneWidget);
    expect(find.byKey(const Key('insights-screen')), findsNothing);
  });

  testWidgets('debug mode shows drafts, clearly marked not approved',
      (tester) async {
    await _open(
      tester,
      insightsFile([insightJson(status: 'draft', reviewedBy: null)]),
      showUnapproved: true,
    );
    await tester.tap(find.byKey(const Key('reader-insights-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.insightNotApproved), findsOneWidget);
    expect(find.text(AppStrings.insightApproved), findsNothing);
  });

  testWidgets('the insights route for a section without any shows the empty state',
      (tester) async {
    await _open(tester, approved,
        path: '$_sectionPath/insights'.replaceAll('sec-a-001/insights',
            'sec-a-002/insights'));
    expect(find.byKey(const Key('empty-view')), findsOneWidget);
    expect(find.text(AppStrings.insightsNone), findsOneWidget);
  });

  testWidgets('an invalid insights file never breaks reading',
      (tester) async {
    await _open(tester,
        insightsFile([insightJson(sectionId: 'nope')]));
    expect(find.byKey(const Key('reader-screen')), findsOneWidget);
    expect(find.byKey(const Key('para-p-000001')), findsOneWidget);
    expect(find.byKey(const Key('reader-insights-button')), findsNothing);
  });
}
