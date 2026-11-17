import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../domain/reading_prefs.dart';

class ReadingPrefsState {
  const ReadingPrefsState({
    this.prefs = ReadingPrefs.defaults,
    this.loaded = false,
    this.error,
  });

  final ReadingPrefs prefs;

  /// True once the saved values have been read (or the user changed one).
  final bool loaded;

  /// Set when the last save failed; the new value still applies this session.
  final String? error;
}

/// App-wide reading preferences. Changes apply at once, then are saved (in
/// order). A failed save never blocks reading.
class ReadingPrefsCubit extends Cubit<ReadingPrefsState> {
  ReadingPrefsCubit(this._store) : super(const ReadingPrefsState());

  final PrefsStore _store;
  bool _changedByUser = false;
  Future<void> _saveChain = Future<void>.value();

  ReadingPrefs get prefs => state.prefs;

  Future<void> load() async {
    try {
      final saved = await _store.load();
      if (isClosed) return;
      // A change made while loading wins over the older saved value.
      if (_changedByUser) return;
      emit(ReadingPrefsState(prefs: saved, loaded: true));
    } catch (e) {
      debugPrint('Reading preferences load failed: $e');
      if (isClosed || _changedByUser) return;
      emit(const ReadingPrefsState(loaded: true));
    }
  }

  Future<void> larger() {
    final p = prefs;
    if (!p.canIncrease) return Future<void>.value();
    final i = ReadingPrefs.textScaleSteps.indexOf(p.textScale);
    return setTextScale(ReadingPrefs.textScaleSteps[i + 1]);
  }

  Future<void> smaller() {
    final p = prefs;
    if (!p.canDecrease) return Future<void>.value();
    final i = ReadingPrefs.textScaleSteps.indexOf(p.textScale);
    return setTextScale(ReadingPrefs.textScaleSteps[i - 1]);
  }

  Future<void> setTextScale(double value) =>
      _update(prefs.copyWith(textScale: ReadingPrefs.snapTextScale(value)));

  Future<void> setLineSpacing(LineSpacing value) =>
      _update(prefs.copyWith(lineSpacing: value));

  Future<void> resetTextScale() =>
      setTextScale(ReadingPrefs.defaultTextScale);

  Future<void> resetAll() => _update(ReadingPrefs.defaults);

  Future<void> _update(ReadingPrefs next) {
    _changedByUser = true;
    emit(ReadingPrefsState(prefs: next, loaded: true));
    final done = _saveChain.then((_) async {
      try {
        await _store.save(next);
      } catch (e) {
        debugPrint('Reading preferences save failed: $e');
        if (!isClosed) {
          emit(ReadingPrefsState(
            prefs: state.prefs,
            loaded: true,
            error: AppStrings.prefsSaveFailed,
          ));
        }
      }
    });
    _saveChain = done;
    return done;
  }
}
