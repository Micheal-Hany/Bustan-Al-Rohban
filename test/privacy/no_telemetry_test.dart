import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Version 1 has no analytics, ads or crash-reporting SDK (docs/PRIVACY.md).
/// This test keeps it that way: adding one fails here and forces a privacy
/// review (SPEC 14.3: crash reporting must not capture chat text, and must be
/// disclosed).
final _banned = RegExp(
  r'(firebase|crashlytics|sentry|bugsnag|appcenter|datadog|newrelic|mixpanel|'
  r'amplitude|posthog|segment|appsflyer|adjust_sdk|facebook_app_events|'
  r'google_mobile_ads|admob|flutter_native_splash_analytics|countly|instabug|'
  r'google-services|play-services-ads|play-services-measurement)',
  caseSensitive: false,
);

void main() {
  test('pubspec.yaml and pubspec.lock list no telemetry or ads package', () {
    for (final f in ['pubspec.yaml', 'pubspec.lock']) {
      final file = File(f);
      if (!file.existsSync()) continue; // the lock file may be absent in CI
      final hit = _banned.firstMatch(file.readAsStringSync());
      expect(hit, isNull, reason: '$f mentions ${hit?.group(0)}');
    }
  });

  test('Android build files and manifests reference no telemetry SDK', () {
    final files = <File>[];
    final android = Directory('android');
    if (android.existsSync()) {
      for (final e in android.listSync(recursive: true)) {
        if (e is! File) continue;
        final n = e.path.replaceAll('\\', '/');
        if (n.contains('/build/') || n.contains('/.gradle/')) continue;
        if (n.endsWith('.gradle') ||
            n.endsWith('.gradle.kts') ||
            n.endsWith('AndroidManifest.xml') ||
            n.endsWith('.properties')) {
          files.add(e);
        }
      }
    }
    expect(files, isNotEmpty);
    for (final f in files) {
      final hit = _banned.firstMatch(f.readAsStringSync());
      expect(hit, isNull, reason: '${f.path} mentions ${hit?.group(0)}');
    }
  });

  test('no Dart source imports a telemetry package', () {
    final import = RegExp(r'''import\s+['"]package:([a-z0-9_]+)''');
    for (final e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      for (final m in import.allMatches(e.readAsStringSync())) {
        expect(_banned.hasMatch(m.group(1)!), isFalse,
            reason: '${e.path} imports ${m.group(1)}');
      }
    }
  });

  test('the only network code is the chat and report clients', () {
    // Anything that opens an HttpClient must be one of these two files.
    final allowed = {
      'lib/features/ai_chat/data/http_chat_api.dart',
      'lib/features/ai_chat/data/http_report_sender.dart',
    };
    final offenders = <String>[];
    for (final e in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final path = e.path.replaceAll('\\', '/');
      final src = e.readAsStringSync();
      if (RegExp(r'HttpClient\(|package:http/|package:dio/').hasMatch(src) &&
          !allowed.contains(path)) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty);
  });
}
