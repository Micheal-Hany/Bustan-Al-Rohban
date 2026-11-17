/// Line spacing choices for the reader (multiplier of the font size).
enum LineSpacing {
  compact(1.6),
  normal(1.9),
  relaxed(2.2);

  const LineSpacing(this.height);

  final double height;
}

/// Reading preferences. Immutable; defaults are the "comfortable" settings.
class ReadingPrefs {
  const ReadingPrefs({
    this.textScale = 1.0,
    this.lineSpacing = LineSpacing.normal,
  });

  /// Allowed text size multipliers, smallest to largest.
  static const textScaleSteps = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0];
  static const defaultTextScale = 1.0;

  static const defaults = ReadingPrefs();

  final double textScale;
  final LineSpacing lineSpacing;

  int get _stepIndex => textScaleSteps.indexOf(textScale);
  bool get canIncrease => _stepIndex < textScaleSteps.length - 1;
  bool get canDecrease => _stepIndex > 0;

  ReadingPrefs copyWith({double? textScale, LineSpacing? lineSpacing}) =>
      ReadingPrefs(
        textScale: textScale ?? this.textScale,
        lineSpacing: lineSpacing ?? this.lineSpacing,
      );

  /// The allowed step closest to [value] (so a stored or imported value that
  /// is not exactly a step still gives a valid size).
  static double snapTextScale(double value) {
    var best = textScaleSteps.first;
    for (final s in textScaleSteps) {
      if ((s - value).abs() < (best - value).abs()) best = s;
    }
    return best;
  }

  @override
  bool operator ==(Object other) =>
      other is ReadingPrefs &&
      other.textScale == textScale &&
      other.lineSpacing == lineSpacing;

  @override
  int get hashCode => Object.hash(textScale, lineSpacing);

  @override
  String toString() => 'ReadingPrefs($textScale, ${lineSpacing.name})';
}

abstract class PrefsStore {
  /// Returns the saved preferences, or [ReadingPrefs.defaults] when nothing
  /// valid is saved.
  Future<ReadingPrefs> load();

  Future<void> save(ReadingPrefs prefs);
}

/// Storage keys shared by store implementations.
class PrefsKeys {
  const PrefsKeys._();

  static const textScale = 'reading.textScale';
  static const lineSpacing = 'reading.lineSpacing';
}

/// Turns stored strings into preferences, tolerating missing or corrupt
/// values (each bad field falls back to its default).
ReadingPrefs parseReadingPrefs({String? textScale, String? lineSpacing}) {
  var scale = ReadingPrefs.defaultTextScale;
  final parsed = textScale == null ? null : double.tryParse(textScale);
  if (parsed != null && parsed.isFinite) {
    scale = ReadingPrefs.snapTextScale(parsed);
  }
  var spacing = LineSpacing.normal;
  for (final s in LineSpacing.values) {
    if (s.name == lineSpacing) spacing = s;
  }
  return ReadingPrefs(textScale: scale, lineSpacing: spacing);
}

class InMemoryPrefsStore implements PrefsStore {
  ReadingPrefs? _saved;

  @override
  Future<ReadingPrefs> load() async => _saved ?? ReadingPrefs.defaults;

  @override
  Future<void> save(ReadingPrefs prefs) async => _saved = prefs;
}
