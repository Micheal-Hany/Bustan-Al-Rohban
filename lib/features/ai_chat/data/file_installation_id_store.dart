import 'dart:io';

import '../domain/client_identity.dart';

/// Keeps the installation id in one small file (created on first use).
class FileInstallationIdStore implements InstallationIdStore {
  FileInstallationIdStore(this._file);

  final File _file;
  String? _cached;

  @override
  Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      if (await _file.exists()) {
        final text = (await _file.readAsString()).trim();
        if (installationIdPattern.hasMatch(text)) return _cached = text;
      }
    } catch (_) {
      // Fall through and make a new id.
    }
    final id = newInstallationId();
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(id, flush: true);
    } catch (_) {
      // Not persisted: the id still works for this run.
    }
    return _cached = id;
  }
}
