import 'dart:async';

import 'package:bustan_al_rohban/app/strings.dart';
import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';
import 'package:bustan_al_rohban/features/settings/presentation/reading_prefs_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Store with switchable failures and an optional gate on load.
class _ControlledStore implements PrefsStore {
  _ControlledStore([this.saved = ReadingPrefs.defaults]);

  ReadingPrefs saved;
  bool failSave = false;
  bool failLoad = false;
  Completer<void>? loadGate;
  final List<ReadingPrefs> writes = [];

  @override
  Future<ReadingPrefs> load() async {
    if (failLoad) throw StateError('load failed');
    final g = loadGate;
    if (g != null) await g.future;
    return saved;
  }

  @override
  Future<void> save(ReadingPrefs prefs) async {
    if (failSave) throw StateError('save failed');
    writes.add(prefs);
    saved = prefs;
  }
}

void main() {
  group('ReadingPrefsCubit', () {
    test('starts with defaults, not yet loaded', () {
      final c = ReadingPrefsCubit(InMemoryPrefsStore());
      expect(c.state.prefs, ReadingPrefs.defaults);
      expect(c.state.loaded, isFalse);
    });

    test('load applies saved values', () async {
      final store = InMemoryPrefsStore();
      await store.save(const ReadingPrefs(
        textScale: 1.5,
        lineSpacing: LineSpacing.relaxed,
      ));
      final c = ReadingPrefsCubit(store);
      await c.load();
      expect(c.state.loaded, isTrue);
      expect(c.state.prefs.textScale, 1.5);
      expect(c.state.prefs.lineSpacing, LineSpacing.relaxed);
      await c.close();
    });

    test('larger and smaller step through the sizes', () async {
      final c = ReadingPrefsCubit(InMemoryPrefsStore())..load();
      await c.larger();
      expect(c.prefs.textScale, 1.15);
      await c.larger();
      expect(c.prefs.textScale, 1.3);
      await c.smaller();
      await c.smaller();
      await c.smaller();
      expect(c.prefs.textScale, 0.85);
      await c.close();
    });

    test('larger stops at the maximum, smaller at the minimum', () async {
      final c = ReadingPrefsCubit(InMemoryPrefsStore())..load();
      for (var i = 0; i < 20; i++) {
        await c.larger();
      }
      expect(c.prefs.textScale, 2.0);
      expect(c.prefs.canIncrease, isFalse);
      for (var i = 0; i < 20; i++) {
        await c.smaller();
      }
      expect(c.prefs.textScale, 0.85);
      expect(c.prefs.canDecrease, isFalse);
      await c.close();
    });

    test('setTextScale snaps to a valid size', () async {
      final c = ReadingPrefsCubit(InMemoryPrefsStore())..load();
      await c.setTextScale(1.2);
      expect(c.prefs.textScale, 1.15);
      await c.close();
    });

    test('line spacing can be changed', () async {
      final c = ReadingPrefsCubit(InMemoryPrefsStore())..load();
      await c.setLineSpacing(LineSpacing.compact);
      expect(c.prefs.lineSpacing, LineSpacing.compact);
      await c.close();
    });

    test('resetTextScale keeps the spacing; resetAll resets both', () async {
      final c = ReadingPrefsCubit(InMemoryPrefsStore())..load();
      await c.setTextScale(1.75);
      await c.setLineSpacing(LineSpacing.relaxed);
      await c.resetTextScale();
      expect(c.prefs.textScale, 1.0);
      expect(c.prefs.lineSpacing, LineSpacing.relaxed);
      await c.resetAll();
      expect(c.prefs, ReadingPrefs.defaults);
      await c.close();
    });

    test('changes are saved', () async {
      final store = _ControlledStore();
      final c = ReadingPrefsCubit(store)..load();
      await c.larger();
      await c.setLineSpacing(LineSpacing.relaxed);
      expect(store.saved.textScale, 1.15);
      expect(store.saved.lineSpacing, LineSpacing.relaxed);
      await c.close();
    });

    test('values survive a restart (new cubit, same store)', () async {
      final store = InMemoryPrefsStore();
      final first = ReadingPrefsCubit(store)..load();
      await first.setTextScale(1.5);
      await first.setLineSpacing(LineSpacing.compact);
      await first.close();

      final second = ReadingPrefsCubit(store);
      await second.load();
      expect(second.prefs.textScale, 1.5);
      expect(second.prefs.lineSpacing, LineSpacing.compact);
      await second.close();
    });

    test('rapid changes are saved in order; the last one wins', () async {
      final store = _ControlledStore();
      final c = ReadingPrefsCubit(store)..load();
      await Future.wait([c.larger(), c.larger(), c.larger()]);
      expect(store.writes.map((p) => p.textScale), [1.15, 1.3, 1.5]);
      expect(store.saved.textScale, 1.5);
      await c.close();
    });

    test('a change made while loading is not overwritten by the load',
        () async {
      final store = _ControlledStore(const ReadingPrefs(textScale: 0.85))
        ..loadGate = Completer<void>();
      final c = ReadingPrefsCubit(store);
      final loading = c.load();
      await c.setTextScale(1.75);
      store.loadGate!.complete();
      await loading;
      expect(c.prefs.textScale, 1.75);
      await c.close();
    });

    test('a failed save keeps the value for this session and reports it',
        () async {
      final store = _ControlledStore()..failSave = true;
      final c = ReadingPrefsCubit(store)..load();
      await c.larger();
      expect(c.prefs.textScale, 1.15);
      expect(c.state.error, AppStrings.prefsSaveFailed);
      await c.close();
    });

    test('a failed load falls back to defaults', () async {
      final store = _ControlledStore()..failLoad = true;
      final c = ReadingPrefsCubit(store);
      await c.load();
      expect(c.state.loaded, isTrue);
      expect(c.prefs, ReadingPrefs.defaults);
      await c.close();
    });

    test('closing while loading does not throw', () async {
      final store = _ControlledStore()..loadGate = Completer<void>();
      final c = ReadingPrefsCubit(store);
      final f = c.load();
      await c.close();
      store.loadGate!.complete();
      await f;
    });
  });
}
