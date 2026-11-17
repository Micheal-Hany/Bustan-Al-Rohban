# Local database migrations

Local user data (bookmarks, reading progress, and later chat history) is stored with Drift in `bustan.sqlite` (private app storage). Schema: `lib/core/db/app_database.dart`.

## Rules

1. Any table or column change bumps `schemaVersion` in `AppDatabase` and adds a step in `onUpgrade`.
2. Never edit an old migration step; add a new one.
3. User data is never dropped silently. A step that cannot preserve data needs an owner decision first.
4. Identity is the paragraph ID, never a list position or a section number. Section and saint IDs stored in rows are lookup **hints** only; readers resolve a paragraph by its ID (see `LibraryRepository.locate`).
5. `contentVersion` is stored with each bookmark/progress row (the version it was created under).
6. Chat history is excluded from Android backups (Task 9).

## Version history

| Version | Change |
|---|---|
| 1 | `bookmarks` (unique per paragraph + offset) and `reading_progress` (one row per section). |
| 2 | Added `app_settings` (key/value) for reading preferences. Upgrade creates the table; bookmarks and progress are untouched. |
