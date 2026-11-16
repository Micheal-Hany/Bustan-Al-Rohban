import 'package:bustan_al_rohban/features/search/presentation/search_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';
import 'search_test_support.dart';

SearchCubit _cubit(ProbeSource source,
        {Duration debounce = const Duration(milliseconds: 20)}) =>
    SearchCubit(searchRepoFor(source), debounce: debounce);

void main() {
  group('SearchCubit', () {
    test('starts idle', () {
      final c = _cubit(probeFor(searchBook()));
      expect(c.state.status, SearchStatus.idle);
      c.close();
    });

    test('submit builds the index, then shows results', () async {
      final c = _cubit(probeFor(searchBook()));
      final states = <SearchStatus>[];
      final sub = c.stream.listen((s) => states.add(s.status));
      await c.submit('رحمة');
      await sub.cancel();
      expect(states, [SearchStatus.building, SearchStatus.results]);
      expect(c.state.response!.total, 2);
      expect(c.state.query, 'رحمة');
      await c.close();
    });

    test('a second search does not show the building state again', () async {
      final c = _cubit(probeFor(searchBook()));
      await c.submit('رحمة');
      final states = <SearchStatus>[];
      final sub = c.stream.listen((s) => states.add(s.status));
      await c.submit('محبة');
      await sub.cancel();
      expect(states, [SearchStatus.results]);
      await c.close();
    });

    test('no match gives noResults', () async {
      final c = _cubit(probeFor(searchBook()));
      await c.submit('غير موجود');
      expect(c.state.status, SearchStatus.noResults);
      await c.close();
    });

    test('blank and punctuation-only queries go back to idle', () async {
      final c = _cubit(probeFor(searchBook()));
      await c.submit('رحمة');
      await c.submit('   ');
      expect(c.state.status, SearchStatus.idle);
      await c.submit('رحمة');
      await c.submit('،؟');
      expect(c.state.status, SearchStatus.idle);
      await c.close();
    });

    test('typing is debounced', () async {
      final c = _cubit(probeFor(searchBook()));
      c.queryChanged('رح');
      c.queryChanged('رحمة');
      expect(c.state.status, SearchStatus.idle, reason: 'not yet');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(c.state.status, SearchStatus.results);
      expect(c.state.query, 'رحمة');
      await c.close();
    });

    test('clearing the query cancels a pending search', () async {
      final c = _cubit(probeFor(searchBook()));
      c.queryChanged('رحمة');
      c.queryChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(c.state.status, SearchStatus.idle);
      await c.close();
    });

    test('an older slow answer never overwrites a newer query', () async {
      final source = probeFor(searchBook())..hold();
      final c = _cubit(source);
      final first = c.search('رحمة');
      final second = c.search('محبة');
      source.release();
      await Future.wait([first, second]);
      expect(c.state.query, 'محبة');
      expect(c.state.status, SearchStatus.results);
      await c.close();
    });

    test('a content error gives the error state; retry recovers', () async {
      final source = probeFor(searchBook());
      final mem = source.inner as InMemoryContentSource;
      final good = mem.files['saints/saint-a.json']!;
      mem.files['saints/saint-a.json'] = '{ broken';
      final c = _cubit(source);
      await c.submit('رحمة');
      expect(c.state.status, SearchStatus.error);
      expect(c.state.error, isNotEmpty);
      mem.files['saints/saint-a.json'] = good;
      await c.retry();
      expect(c.state.status, SearchStatus.results);
      await c.close();
    });

    test('closing while a search is pending does not throw', () async {
      final source = probeFor(searchBook())..hold();
      final c = _cubit(source);
      final f = c.search('رحمة');
      await c.close();
      source.release();
      await f;
    });
  });
}
