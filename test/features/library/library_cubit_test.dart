import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/core/content/content_models.dart';
import 'package:bustan_al_rohban/features/library/presentation/library_cubit.dart';
import 'package:bustan_al_rohban/features/library/presentation/load_status.dart';
import 'package:bustan_al_rohban/features/library/presentation/page_label.dart';
import 'package:bustan_al_rohban/features/library/presentation/saint_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import 'library_test_support.dart';

void main() {
  group('LibraryCubit', () {
    test('starts loading, then loaded with ordered saints', () async {
      final cubit = LibraryCubit(repoFor(probeFor(twoSaintBook())));
      expect(cubit.state.status, LoadStatus.loading);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      expect(cubit.state.saints.map((s) => s.id), ['saint-a', 'saint-b']);
      expect(cubit.state.manifest!.title, 'كتاب');
      await cubit.close();
    });

    test('empty book gives empty status', () async {
      final cubit = LibraryCubit(repoFor(probeFor(buildBook([]))));
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('missing manifest gives error status with a message', () async {
      final source = probeFor(twoSaintBook());
      (source.inner as InMemoryContentSource).files.remove('manifest.json');
      final cubit = LibraryCubit(repoFor(source));
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.error, contains('missing-file'));
      await cubit.close();
    });

    test('load again after an error recovers', () async {
      final book = twoSaintBook();
      final source = probeFor(book);
      final mem = source.inner as InMemoryContentSource;
      mem.files.remove('manifest.json');
      final cubit = LibraryCubit(repoFor(source));
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      mem.files['manifest.json'] = book.manifestJson;
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      await cubit.close();
    });

    test('closing while loading does not throw', () async {
      final source = probeFor(twoSaintBook())..hold();
      final cubit = LibraryCubit(repoFor(source));
      final future = cubit.load();
      await cubit.close();
      source.release();
      await future;
    });
  });

  group('SaintCubit', () {
    test('loads sections of one saint', () async {
      final cubit = SaintCubit(repoFor(probeFor(twoSaintBook())), 'saint-a');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.loaded);
      expect(cubit.state.saint!.sections.map((s) => s.id),
          ['sec-a-001', 'sec-a-002']);
      await cubit.close();
    });

    test('saint without sections is empty', () async {
      final book = buildBook([saintJson(sections: [])]);
      final cubit = SaintCubit(repoFor(probeFor(book)), 'saint-a');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.empty);
      await cubit.close();
    });

    test('unknown saint gives error status', () async {
      final cubit = SaintCubit(repoFor(probeFor(twoSaintBook())), 'zzz');
      await cubit.load();
      expect(cubit.state.status, LoadStatus.error);
      await cubit.close();
    });
  });

  group('pageLabel', () {
    Section sec(int? a, int? b) => Section(
          id: 'sec-x-001',
          title: 't',
          order: 1,
          pageStart: a,
          pageEnd: b,
          paragraphs: const [],
        );

    test('single page, range, and unknown', () {
      expect(pageLabel(sec(3, 3)), '${AppStrings.pageWord} 3');
      expect(pageLabel(sec(3, 5)), '${AppStrings.pageWord} 3-5');
      expect(pageLabel(sec(null, null)), AppStrings.pagesUnknown);
    });
  });
}
