import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/bloc_observer.dart';
import 'core/db/app_database.dart';
import 'core/db/connection.dart';
import 'features/ai_chat/data/chat_connection.dart';
import 'features/ai_chat/data/chat_database.dart';
import 'features/ai_chat/data/drift_chat_store.dart';
import 'features/ai_chat/data/file_installation_id_store.dart';
import 'features/ai_chat/data/http_chat_api.dart';
import 'features/ai_chat/domain/chat_api.dart';
import 'features/ai_chat/domain/client_identity.dart';
import 'features/bookmarks/data/drift_bookmark_store.dart';
import 'features/reader/progress/drift_progress_store.dart';
import 'features/settings/data/drift_prefs_store.dart';

/// Backend address, set at build time: `--dart-define=CHAT_API_BASE_URL=https://...`.
/// Empty means "not configured" (debug builds fall back to the Android
/// emulator's address for a backend running on the host computer).
const _chatBaseUrl = String.fromEnvironment('CHAT_API_BASE_URL');

/// Development/CI only (backend `ATTESTATION_MODE=test`).
const _attestationTestToken = String.fromEnvironment('ATTESTATION_TEST_TOKEN');

ChatApi _createChatApi() {
  final url = _chatBaseUrl.isNotEmpty
      ? _chatBaseUrl
      : (kDebugMode ? 'http://10.0.2.2:3000' : '');
  return url.isEmpty ? const UnconfiguredChatApi() : HttpChatApi(baseUrl: url);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  // Opened lazily on the first query; private app storage.
  final db = AppDatabase(openAppConnection());
  // Chat history has its own file so Android backups can exclude it.
  final chatDb = ChatDatabase(openChatConnection());
  runApp(BustanApp(
    chatStore: DriftChatStore(chatDb),
    chatApi: _createChatApi(),
    installationIds: _LazyInstallationIdStore(),
    attestation: _attestationTestToken.isEmpty
        ? const NoAttestationProvider()
        : const FixedAttestationProvider(_attestationTestToken),
    bookmarkStore: DriftBookmarkStore(db),
    progressStore: DriftProgressStore(db),
    prefsStore: DriftPrefsStore(db),
  ));
}

/// Resolves the app-support folder on first use, then keeps the id in a file.
class _LazyInstallationIdStore implements InstallationIdStore {
  InstallationIdStore? _inner;

  @override
  Future<String> get() async {
    var inner = _inner;
    if (inner == null) {
      final dir = await getApplicationSupportDirectory();
      inner = FileInstallationIdStore(File(p.join(dir.path, 'installation_id')));
      _inner = inner;
    }
    return inner.get();
  }
}
