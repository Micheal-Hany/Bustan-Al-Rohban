import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/bloc_observer.dart';
import 'core/db/app_database.dart';
import 'core/db/connection.dart';
import 'features/ai_chat/data/chat_connection.dart';
import 'features/ai_chat/data/chat_database.dart';
import 'features/ai_chat/data/drift_chat_store.dart';
import 'features/bookmarks/data/drift_bookmark_store.dart';
import 'features/reader/progress/drift_progress_store.dart';
import 'features/settings/data/drift_prefs_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  // Opened lazily on the first query; private app storage.
  final db = AppDatabase(openAppConnection());
  // Chat history has its own file so Android backups can exclude it.
  final chatDb = ChatDatabase(openChatConnection());
  runApp(BustanApp(
    chatStore: DriftChatStore(chatDb),
    bookmarkStore: DriftBookmarkStore(db),
    progressStore: DriftProgressStore(db),
    prefsStore: DriftPrefsStore(db),
  ));
}