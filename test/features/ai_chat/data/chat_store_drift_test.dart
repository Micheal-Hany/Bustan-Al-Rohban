import 'dart:io';

import 'package:bustan_al_rohban/features/ai_chat/data/chat_database.dart';
import 'package:bustan_al_rohban/features/ai_chat/data/drift_chat_store.dart';
import 'package:bustan_al_rohban/features/ai_chat/domain/chat_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'chat_store_contract.dart';

/// Needs the generated `chat_database.g.dart` (run build_runner, see README)
/// and the sqlite3 native library; without the library these are skipped.
bool _sqliteAvailable() {
  try {
    sqlite3.openInMemory().dispose();
    return true;
  } catch (_) {
    return false;
  }
}

final Object? _skip = _sqliteAvailable()
    ? null
    : 'sqlite3 native library not found (see README, Task 5)';

ChatDatabase _memoryDb() {
  final db = ChatDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

void main() {
  runChatStoreContract(
    'Drift',
    (newId, clock) async =>
        DriftChatStore(_memoryDb(), newId: newId, clock: clock),
    skip: _skip,
  );

  group('Chat database', skip: _skip, () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bustan_chat_test');
      addTearDown(() => dir.deleteSync(recursive: true));
    });

    test('schema version is 1', () {
      expect(_memoryDb().schemaVersion, 1);
    });

    test('deleting a conversation leaves no message rows behind', () async {
      final db = _memoryDb();
      final store = DriftChatStore(db);
      final c = await store.createConversation();
      final other = await store.createConversation();
      await store.addMessage(
          conversationId: c.id, role: ChatRole.user, content: 'x');
      await store.addMessage(
          conversationId: c.id, role: ChatRole.assistant, content: 'y');
      await store.addMessage(
          conversationId: other.id, role: ChatRole.user, content: 'z');
      expect(await db.select(db.chatMessageRows).get(), hasLength(3));
      await store.deleteConversation(c.id);
      final left = await db.select(db.chatMessageRows).get();
      expect(left.map((r) => r.content), ['z']);
    });

    test('history survives closing and reopening the database file',
        () async {
      final file = File('${dir.path}/chat.sqlite');
      final db1 = ChatDatabase(NativeDatabase(file));
      final s1 = DriftChatStore(db1);
      final c = await s1.createConversation(
          scope: ChatScopeKind.saint, saintId: 'saint-a');
      await s1.addMessage(
          conversationId: c.id, role: ChatRole.user, content: 'ما هو الصوم؟');
      await s1.addMessage(
          conversationId: c.id,
          role: ChatRole.assistant,
          content: 'جواب',
          metaJson: '{"a":1}');
      await db1.close();

      // "Restart": a brand-new database object on the same file.
      final db2 = ChatDatabase(NativeDatabase(file));
      addTearDown(db2.close);
      final s2 = DriftChatStore(db2);
      final list = await s2.conversations();
      expect(list.single.id, c.id);
      expect(list.single.title, 'ما هو الصوم؟');
      expect(list.single.scope, ChatScopeKind.saint);
      final msgs = await s2.messages(c.id);
      expect(msgs.map((m) => m.content), ['ما هو الصوم؟', 'جواب']);
      expect(msgs.last.metaJson, '{"a":1}');

      // ...and the conversation can be continued.
      final next = await s2.addMessage(
          conversationId: c.id, role: ChatRole.user, content: 'متابعة');
      expect(next.seq, 3);
    });
  });
}
