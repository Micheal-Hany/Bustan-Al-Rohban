import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'content_models.dart';

/// Canonical hash of the book content. It depends only on parsed data (not on
/// file whitespace or line endings), so the app and the backend can compare
/// corpora reliably.
///
/// Canonical text, one line per item, joined with "\n":
///   S<TAB>saintId
///   C<TAB>sectionId<TAB>sectionTitle
///   P<TAB>paragraphId<TAB>page-or-?<TAB>kind<TAB>text
class ContentHasher {
  const ContentHasher._();

  static String hash(Iterable<Saint> saints) {
    final lines = <String>[];
    for (final saint in saints) {
      lines.add('S\t${saint.id}');
      for (final section in saint.sections) {
        lines.add('C\t${section.id}\t${section.title}');
        for (final p in section.paragraphs) {
          lines.add('P\t${p.id}\t${p.page ?? '?'}\t${p.kind.name}\t${p.text}');
        }
      }
    }
    final digest = sha256.convert(utf8.encode(lines.join('\n')));
    return 'sha256:$digest';
  }
}
