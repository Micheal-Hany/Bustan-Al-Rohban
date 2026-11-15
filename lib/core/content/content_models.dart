enum ParagraphKind { body, heading }

class Paragraph {
  const Paragraph({
    required this.id,
    required this.order,
    required this.kind,
    required this.page,
    required this.text,
  });

  final String id;
  final int order;
  final ParagraphKind kind;

  /// Printed page where the paragraph starts; `null` when unknown.
  final int? page;

  /// Exact original text. Never normalized or modified.
  final String text;
}

class Section {
  const Section({
    required this.id,
    required this.title,
    required this.order,
    required this.pageStart,
    required this.pageEnd,
    required this.paragraphs,
  });

  final String id;
  final String title;
  final int order;
  final int? pageStart;
  final int? pageEnd;
  final List<Paragraph> paragraphs;
}

class Saint {
  const Saint({
    required this.id,
    required this.title,
    required this.order,
    required this.aliases,
    required this.sections,
  });

  final String id;
  final String title;
  final int order;
  final List<String> aliases;
  final List<Section> sections;

  int get paragraphCount =>
      sections.fold(0, (sum, s) => sum + s.paragraphs.length);
}

class SaintEntry {
  const SaintEntry({
    required this.id,
    required this.title,
    required this.order,
    required this.aliases,
    required this.file,
    required this.sectionCount,
    required this.paragraphCount,
  });

  final String id;
  final String title;
  final int order;
  final List<String> aliases;
  final String file;
  final int sectionCount;
  final int paragraphCount;
}

class ContentManifest {
  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.bookId,
    required this.title,
    required this.language,
    required this.fixture,
    required this.edition,
    required this.saints,
    required this.contentHash,
  });

  final int schemaVersion;
  final int contentVersion;
  final String bookId;
  final String title;
  final String language;

  /// `true` for FAKE test content. Must never ship in a release build.
  final bool fixture;
  final Map<String, String> edition;
  final List<SaintEntry> saints;
  final String contentHash;
}

class ContentBook {
  const ContentBook({required this.manifest, required this.saints});

  final ContentManifest manifest;
  final List<Saint> saints;

  Saint? saintById(String id) {
    for (final s in saints) {
      if (s.id == id) return s;
    }
    return null;
  }
}
