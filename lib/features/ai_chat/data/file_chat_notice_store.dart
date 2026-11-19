import 'dart:io';

import '../domain/chat_notice_store.dart';

/// One marker file in app-support storage.
class FileChatNoticeStore implements ChatNoticeStore {
  FileChatNoticeStore(this._file);

  final File _file;

  @override
  Future<bool> accepted() async {
    try {
      return await _file.exists();
    } catch (_) {
      return false; // shows the notice again: the safe direction
    }
  }

  @override
  Future<void> accept() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString('1', flush: true);
    } catch (_) {
      // Not persisted: the notice will simply be shown again next time.
    }
  }
}
