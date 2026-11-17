# Local database migrations

Local user data (bookmarks, reading progress, and later chat history) is stored with Drift in `bustan.sqlite` (private app storage). Schema: `lib/core/db/app_database.dart`.

## Rules

1. Any table or column change bumps `schemaVersion` in `AppDatabase` and adds a step in `onUpgrade`.
2. Never edit an old migration step; add a new one.
3. User data is never dropped silently. A step that cannot preserve data needs an owner decision first.
4. Identity is the paragraph ID, never a list position or a section number. Section and saint IDs stored in rows are lookup **hints** only; readers resolve a paragraph by its ID (see `LibraryRepository.locate`).
5. `contentVersion` is stored with each bookmark/progress row (the version it was created under).
6. Chat history lives in a **separate database file**, `chat/chat.sqlite` (`lib/features/ai_chat/data/chat_database.dart`, own `schemaVersion`), so Android backups can exclude exactly it: `res/xml/backup_rules.xml` (Android 11-) and `res/xml/data_extraction_rules.xml` (Android 12+, cloud backup and device transfer) exclude the `chat/` folder, and the manifest references both. `backup_rules_test.dart` checks this. Do not move chat tables into `bustan.sqlite`.
7. Chat deletion cascades from `conversations` to `chat_messages` (foreign keys are switched on when the database opens).

## Version history

| Version | Change |
|---|---|
| 1 | `bookmarks` (unique per paragraph + offset) and `reading_progress` (one row per section). |
| 2 | Added `app_settings` (key/value) for reading preferences. Upgrade creates the table; bookmarks and progress are untouched. |

### Chat database (`chat/chat.sqlite`)

| Version | Change |
|---|---|
| 1 | `conversations` (id, title, scope, saintId, sectionId, timestamps) and `chat_messages` (id, conversationId with ON DELETE CASCADE, seq, role, content, status, metaJson, createdAtMs; unique per conversation + seq). |
