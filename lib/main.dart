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
import 'features/ai_chat/data/file_chat_notice_store.dart';
import 'features/ai_chat/data/file_installation_id_store.dart';
import 'features/ai_chat/data/http_report_sender.dart';
import 'features/ai_chat/domain/chat_notice_store.dart';
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

String get _baseUrl => _chatBaseUrl.isNotEmpty
    ? _chatBaseUrl
    : (kDebugMode ? 'http://10.0.2.2:3000' : '');

ChatApi _createChatApi() =>
    _baseUrl.isEmpty ? const UnconfiguredChatApi() : HttpChatApi(baseUrl: _baseUrl);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  // Opened lazily on the first query; private app storage.
  final db = AppDatabase(openAppConnection());
  // Chat history has its own file so Android backups can exclude it.
  final chatDb = ChatDatabase(openChatConnection());
  final installationIds = _LazyInstallationIdStore();
  final AttestationProvider attestation = _attestationTestToken.isEmpty
      ? const NoAttestationProvider()
      : const FixedAttestationProvider(_attestationTestToken);
  runApp(BustanApp(
    chatStore: DriftChatStore(chatDb),
    chatApi: _createChatApi(),
    installationIds: installationIds,
    attestation: attestation,
    reportSender: HttpReportSender(
      baseUrl: _baseUrl,
      installationIds: installationIds,
      attestation: attestation,
    ),
    chatNoticeStore: _LazyChatNoticeStore(),
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

/// The "what is sent" notice marker, in app-support storage.
class _LazyChatNoticeStore implements ChatNoticeStore {
  ChatNoticeStore? _inner;

  Future<ChatNoticeStore> _store() async => _inner ??= FileChatNoticeStore(
      File(p.join((await getApplicationSupportDirectory()).path, 'chat_notice_seen')));

  @override
  Future<bool> accepted() async => (await _store()).accepted();

  @override
  Future<void> accept() async => (await _store()).accept();
}
