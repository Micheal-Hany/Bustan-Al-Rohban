import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../library/presentation/page_label.dart';
import 'editorial.dart';

/// One row of the reader list. Built once per section from the content.
sealed class ReaderItem {
  const ReaderItem();

  /// Non-null only for original paragraphs: the stable anchor.
  String? get paragraphId => null;
}

class HeaderItem extends ReaderItem {
  const HeaderItem({
    required this.saintTitle,
    required this.sectionTitle,
    required this.pageText,
  });

  final String saintTitle;
  final String sectionTitle;
  final String pageText;
}

class EditorialItem extends ReaderItem {
  const EditorialItem(this.addition);

  final EditorialAddition addition;
}

/// "Text below starts on page N" (or "page unknown" when [page] is null).
class PageMarkerItem extends ReaderItem {
  const PageMarkerItem(this.page);

  final int? page;

  String get label =>
      page == null ? AppStrings.pagesUnknown : '${AppStrings.pageWord} $page';
}

class ParagraphItem extends ReaderItem {
  const ParagraphItem(this.paragraph);

  final Paragraph paragraph;

  @override
  String get paragraphId => paragraph.id;
}

/// header, editorial additions, then the original paragraphs. A page marker is
/// inserted whenever the page changes (including to/from "unknown").
List<ReaderItem> buildReaderItems({
  required Saint saint,
  required Section section,
  List<EditorialAddition> editorial = const [],
}) {
  final items = <ReaderItem>[
    HeaderItem(
      saintTitle: saint.title,
      sectionTitle: section.title,
      pageText: pageLabel(section),
    ),
    for (final e in editorial) EditorialItem(e),
  ];
  var first = true;
  int? last;
  for (final p in section.paragraphs) {
    if (first || p.page != last) items.add(PageMarkerItem(p.page));
    first = false;
    last = p.page;
    items.add(ParagraphItem(p));
  }
  return items;
}

/// Index of the paragraph with [paragraphId], or -1.
int indexOfParagraph(List<ReaderItem> items, String paragraphId) =>
    items.indexWhere((i) => i.paragraphId == paragraphId);
