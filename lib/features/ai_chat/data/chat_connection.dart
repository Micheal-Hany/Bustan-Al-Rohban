import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sub-folder of the app's files directory that holds the chat database.
/// The Android backup rules exclude exactly this folder; a test keeps the two
/// in sync.
const chatDbFolder = 'chat';
const chatDbFileName = 'chat.sqlite';

/// Opens the chat database (lazily, on the first query).
QueryExecutor openChatConnection() {
  return LazyDatabase(() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, chatDbFolder));
    await dir.create(recursive: true);
    return NativeDatabase.createInBackground(
        File(p.join(dir.path, chatDbFileName)));
  });
}
