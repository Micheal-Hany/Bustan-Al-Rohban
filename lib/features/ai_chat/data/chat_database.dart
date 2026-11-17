import 'package:drift/drift.dart';

part 'chat_database.g.dart';

/// Chat history lives in its OWN database file (`chat/chat.sqlite`), separate
/// from bookmarks and progress, so Android backups can exclude exactly the
/// chat history (see android/app/src/main/res/xml/*.xml and
/// docs/DB_MIGRATIONS.md).
@DataClassName('ConversationRow')
class ConversationRows extends Table {
  @override
  String get tableName => 'conversations';

  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// `book`, `saint` or `section`.
  TextColumn get scope => text()();
  TextColumn get saintId => text().nullable()();
  TextColumn get sectionId => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChatMessageRow')
class ChatMessageRows extends Table {
  @override
  String get tableName => 'chat_messages';

  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(ConversationRows, #id, onDelete: KeyAction.cascade)();

  /// 1-based order inside the conversation.
  IntColumn get seq => integer()();

  /// `user` or `assistant`.
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// `sent`, `pending` or `failed`.
  TextColumn get status => text()();
  TextColumn get metaJson => text().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {conversationId, seq},
      ];
}

@DriftDatabase(tables: [ConversationRows, ChatMessageRows])
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase(super.executor);

  /// Bump on every table change and add a step in [migration]. See
  /// docs/DB_MIGRATIONS.md.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // Needed for ON DELETE CASCADE.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
