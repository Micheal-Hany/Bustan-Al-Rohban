import 'dart:async';

import '../domain/reader_items.dart';

/// Turns "first visible list index" updates into debounced progress saves.
/// The saved position is a paragraph ID (never a list index).
class ProgressTracker {
  ProgressTracker({
    required this.items,
    required this.onSave,
    this.debounce = const Duration(milliseconds: 500),
  });

  final List<ReaderItem> items;
  final void Function(String paragraphId) onSave;
  final Duration debounce;

  Timer? _timer;
  String? _pending;
  String? _lastSaved;

  /// The paragraph at, or the first one after, list index [index].
  String? paragraphAtOrAfter(int index) {
    for (var i = index < 0 ? 0 : index; i < items.length; i++) {
      final id = items[i].paragraphId;
      if (id != null) return id;
    }
    return null;
  }

  void visibleChanged(int firstVisibleIndex) {
    final id = paragraphAtOrAfter(firstVisibleIndex);
    if (id == null || id == _lastSaved || id == _pending) return;
    _pending = id;
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Saves any pending position now.
  void flush() {
    _timer?.cancel();
    _timer = null;
    final id = _pending;
    _pending = null;
    if (id != null) {
      _lastSaved = id;
      onSave(id);
    }
  }

  void dispose() => flush();
}
