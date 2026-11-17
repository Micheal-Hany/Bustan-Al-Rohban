import 'package:drift/drift.dart';

import '../../bookmarks/domain/bookmark.dart';
import '../../bookmarks/domain/bookmark_store.dart' show randomId;
import '../domain/chat_models.dart';
import '../domain/chat_store.dart';
import 'chat_database.dart';

class DriftChatStore implements ChatStore {
  DriftChatStore(this._db, {IdGenerator? newId, Clock? clock})
      : _newId = newId,
        _clock = clock ?? DateTime.now;

  final ChatDatabase _db;
  final IdGenerator? _newId;
  final Clock _clock;

  String _id(String prefix) => _newId?.call() ?? randomId(prefix);

  DateTime _fromMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  T _byName<T extends Enum>(List<T> values, String name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Conversation _conversation(ConversationRow r) => Conversation(
        id: r.id,
        title: r.title,
        scope: _byName(ChatScopeKind.values, r.scope, ChatScopeKind.book),
        saintId: r.saintId,
        sectionId: r.sectionId,
        createdAt: _fromMs(r.createdAtMs),
        updatedAt: _fromMs(r.updatedAtMs),
      );

  ChatMessage _message(ChatMessageRow r) => ChatMessage(
        id: r.id,
        conversationId: r.conversationId,
        seq: r.seq,
        role: _byName(ChatRole.values, r.role, ChatRole.assistant),
        content: r.content,
        status: _byName(MessageStatus.values, r.status, MessageStatus.sent),
        createdAt: _fromMs(r.createdAtMs),
        metaJson: r.metaJson,
      );

  @override
  Future<Conversation> createConversation({
    ChatScopeKind scope = ChatScopeKind.book,
    String? saintId,
    String? sectionId,
  }) async {
    checkScope(scope, saintId, sectionId);
    final now = _clock().millisecondsSinceEpoch;
    final id = _id('conv');
    await _db.into(_db.conversationRows).insert(ConversationRowsCompanion.insert(
          id: id,
          scope: scope.name,
          saintId: Value(saintId),
          sectionId: Value(sectionId),
          createdAtMs: now,
          updatedAtMs: now,
        ));
    return Conversation(
      id: id,
      title: '',
      scope: scope,
      saintId: saintId,
      sectionId: sectionId,
      createdAt: _fromMs(now),
      updatedAt: _fromMs(now),
    );
  }

  @override
  Future<List<Conversation>> conversations() async {
    final rows = await (_db.select(_db.conversationRows)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAtMs),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    return rows.map(_conversation).toList();
  }

  @override
  Future<Conversation?> conversation(String id) async {
    final row = await (_db.select(_db.conversationRows)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _conversation(row);
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    final rows = await (_db.select(_db.chatMessageRows)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return rows.map(_message).toList();
  }

  @override
  Future<ChatMessage> addMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? metaJson,
  }) {
    return _db.transaction(() async {
      final conv = await (_db.select(_db.conversationRows)
            ..where((t) => t.id.equals(conversationId)))
          .getSingleOrNull();
      if (conv == null) throw ConversationNotFound(conversationId);

      final maxSeq = _db.chatMessageRows.seq.max();
      final top = await (_db.selectOnly(_db.chatMessageRows)
            ..addColumns([maxSeq])
            ..where(_db.chatMessageRows.conversationId.equals(conversationId)))
          .map((r) => r.read(maxSeq))
          .getSingle();
      final seq = (top ?? 0) + 1;

      final now = _clock().millisecondsSinceEpoch;
      final id = _id('msg');
      await _db.into(_db.chatMessageRows).insert(ChatMessageRowsCompanion.insert(
            id: id,
            conversationId: conversationId,
            seq: seq,
            role: role.name,
            content: content,
            status: status.name,
            metaJson: Value(metaJson),
            createdAtMs: now,
          ));
      final setTitle = conv.title.isEmpty && role == ChatRole.user;
      await (_db.update(_db.conversationRows)
            ..where((t) => t.id.equals(conversationId)))
          .write(ConversationRowsCompanion(
        updatedAtMs: Value(now),
        title: setTitle ? Value(deriveTitle(content)) : const Value.absent(),
      ));
      return ChatMessage(
        id: id,
        conversationId: conversationId,
        seq: seq,
        role: role,
        content: content,
        status: status,
        createdAt: _fromMs(now),
        metaJson: metaJson,
      );
    });
  }

  @override
  Future<bool> updateMessage(
    String messageId, {
    String? content,
    MessageStatus? status,
    String? metaJson,
  }) async {
    final count = await (_db.update(_db.chatMessageRows)
          ..where((t) => t.id.equals(messageId)))
        .write(ChatMessageRowsCompanion(
      content: content == null ? const Value.absent() : Value(content),
      status: status == null ? const Value.absent() : Value(status.name),
      metaJson: metaJson == null ? const Value.absent() : Value(metaJson),
    ));
    return count > 0;
  }

  @override
  Future<bool> deleteConversation(String id) async {
    // Messages are deleted explicitly (and the schema also cascades), so
    // nothing depends on the foreign_keys pragma being active.
    return _db.transaction(() async {
      await (_db.delete(_db.chatMessageRows)
            ..where((t) => t.conversationId.equals(id)))
          .go();
      final count = await (_db.delete(_db.conversationRows)
            ..where((t) => t.id.equals(id)))
          .go();
      return count > 0;
    });
  }

  @override
  Future<int> clearAll() => _db.transaction(() async {
        await _db.delete(_db.chatMessageRows).go();
        return _db.delete(_db.conversationRows).go();
      });
}
