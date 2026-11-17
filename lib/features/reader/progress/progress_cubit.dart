import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bookmarks/domain/bookmark.dart';
import 'reading_progress.dart';

class ProgressState {
  const ProgressState({this.last});

  /// Most recent reading position (for "continue reading").
  final ReadingProgress? last;
}

/// App-wide reading progress. Saving never throws: a failed save must not
/// interrupt reading.
class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit(this._store, {Clock? clock})
      : _clock = clock ?? DateTime.now,
        super(const ProgressState());

  final ProgressStore _store;
  final Clock _clock;

  Future<void> load() async {
    try {
      final last = await _store.last();
      if (isClosed) return;
      emit(ProgressState(last: last));
    } catch (e) {
      debugPrint('Progress load failed: $e');
    }
  }

  Future<void> record({
    required String saintId,
    required String sectionId,
    required String paragraphId,
    int offset = 0,
    required int contentVersion,
  }) async {
    final p = ReadingProgress(
      saintId: saintId,
      sectionId: sectionId,
      paragraphId: paragraphId,
      offset: offset,
      contentVersion: contentVersion,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _clock().millisecondsSinceEpoch,
        isUtc: true,
      ),
    );
    try {
      await _store.save(p);
      if (isClosed) return;
      emit(ProgressState(last: p));
    } catch (e) {
      debugPrint('Progress save failed: $e');
    }
  }

  Future<ReadingProgress?> forSection(String sectionId) async {
    try {
      return await _store.forSection(sectionId);
    } catch (_) {
      return null;
    }
  }
}
