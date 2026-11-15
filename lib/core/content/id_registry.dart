import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Keeps paragraph IDs stable across re-imports.
///
/// A paragraph is recognised by a fingerprint of (section ID, exact text,
/// occurrence index). A known fingerprint always gets its old ID; a new one
/// gets the next number. Numbers are never reused.
class IdRegistry {
  IdRegistry({int nextNumber = 1, Map<String, String>? paragraphs})
      : _next = nextNumber,
        _ids = {...?paragraphs};

  factory IdRegistry.fromJson(Map<String, dynamic> json) {
    final raw = json['paragraphs'];
    final map = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => map[k.toString()] = v.toString());
    }
    final next = json['nextParagraphNumber'];
    return IdRegistry(nextNumber: next is int ? next : 1, paragraphs: map);
  }

  int _next;
  final Map<String, String> _ids;
  final Set<String> _seen = {};

  Map<String, dynamic> toJson() => {
        'nextParagraphNumber': _next,
        'paragraphs': Map<String, String>.of(_ids),
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  static String fingerprint(String sectionId, String text, int occurrence) {
    final bytes = utf8.encode('$sectionId\u0000$text\u0000$occurrence');
    return sha256.convert(bytes).toString();
  }

  String assign(String fingerprint) {
    _seen.add(fingerprint);
    final existing = _ids[fingerprint];
    if (existing != null) return existing;
    final id = 'p-${_next.toString().padLeft(6, '0')}';
    _next++;
    _ids[fingerprint] = id;
    return id;
  }

  /// IDs known to the registry that were not assigned during this run, i.e.
  /// paragraphs that were edited, moved to another section, or removed.
  List<String> retiredIds() => [
        for (final e in _ids.entries)
          if (!_seen.contains(e.key)) e.value,
      ];
}
