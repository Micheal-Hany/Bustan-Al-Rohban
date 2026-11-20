// Scans files for provider secrets before a release.
//
//   dart run tool/secret_scan.dart <dir> [<dir> ...]
//
// Typical use (Windows 10+ `tar` extracts zip files):
//   mkdir build\apk_scan
//   tar -xf build\app\outputs\flutter-apk\app-release.apk -C build\apk_scan
//   dart run tool/secret_scan.dart build/apk_scan lib assets android pubspec.yaml
//
// Exit code 0 = nothing found, 1 = findings, 2 = bad usage.
// Findings never print the secret itself, only the file and kind.
import 'dart:convert';
import 'dart:io';

class SecretFinding {
  const SecretFinding(this.kind, this.offset);
  final String kind;
  final int offset;

  @override
  String toString() => '$kind at offset $offset';
}

final _patterns = <String, RegExp>{
  'OpenAI-style key': RegExp(r'sk-(?:proj-)?[A-Za-z0-9_\-]{20,}'),
  'Google API key': RegExp(r'AIza[0-9A-Za-z_\-]{35}'),
  'private key block': RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
  'provider key variable': RegExp(
    r'(?:OPENAI|GEMINI|GOOGLE_AI|ANTHROPIC)_API_KEY\s*[=:]\s*\S{8,}',
  ),
  'bearer token': RegExp(r'Bearer\s+[A-Za-z0-9_\-\.]{20,}'),
  'attestation test token value':
      RegExp(r'ATTESTATION_TEST_TOKEN\s*[=:]\s*\S{8,}'),
};

/// Findings in [content]. Offsets are character positions.
List<SecretFinding> findSecrets(String content) {
  final out = <SecretFinding>[];
  _patterns.forEach((kind, re) {
    for (final m in re.allMatches(content)) {
      out.add(SecretFinding(kind, m.start));
    }
  });
  return out;
}

const _skipDirs = {'.git', '.dart_tool', 'node_modules', '.gradle'};

Future<int> scanPaths(List<String> paths, StringSink out) async {
  var total = 0;
  Future<void> scanFile(File f) async {
    final bytes = await f.readAsBytes();
    // latin1 keeps every byte, so binaries (libapp.so, dex) are scanned too.
    final found = findSecrets(latin1.decode(bytes));
    for (final s in found) {
      total++;
      out.writeln('${f.path}: $s');
    }
  }

  for (final p in paths) {
    final type = FileSystemEntity.typeSync(p);
    if (type == FileSystemEntityType.file) {
      await scanFile(File(p));
    } else if (type == FileSystemEntityType.directory) {
      await for (final e in Directory(p).list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        final parts = e.uri.pathSegments;
        if (parts.any(_skipDirs.contains)) continue;
        await scanFile(e);
      }
    } else {
      out.writeln('not found: $p');
      return 2;
    }
  }
  return total == 0 ? 0 : 1;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/secret_scan.dart <dir|file> ...');
    exit(2);
  }
  final code = await scanPaths(args, stdout);
  stdout.writeln(code == 0
      ? 'No secrets found in ${args.join(', ')}'
      : 'Secret scan FAILED');
  exit(code);
}
