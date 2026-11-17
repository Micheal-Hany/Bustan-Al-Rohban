import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the app database file in private app storage (opened lazily on the
/// first query, in a background isolate).
QueryExecutor openAppConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'bustan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
