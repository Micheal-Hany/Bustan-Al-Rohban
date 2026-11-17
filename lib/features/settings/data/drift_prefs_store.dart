import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/reading_prefs.dart';

class DriftPrefsStore implements PrefsStore {
  DriftPrefsStore(this._db);

  final AppDatabase _db;

  @override
  Future<ReadingPrefs> load() async {
    final rows = await _db.select(_db.settingRows).get();
    final values = {for (final r in rows) r.key: r.value};
    return parseReadingPrefs(
      textScale: values[PrefsKeys.textScale],
      lineSpacing: values[PrefsKeys.lineSpacing],
    );
  }

  @override
  Future<void> save(ReadingPrefs prefs) async {
    await _db.transaction(() async {
      Future<void> put(String key, String value) =>
          _db.into(_db.settingRows).insertOnConflictUpdate(
                SettingRowsCompanion.insert(key: key, value: value),
              );
      await put(PrefsKeys.textScale, prefs.textScale.toString());
      await put(PrefsKeys.lineSpacing, prefs.lineSpacing.name);
    });
  }
}
