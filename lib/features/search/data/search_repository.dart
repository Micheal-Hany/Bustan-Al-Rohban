import '../../../core/content/content_models.dart';
import '../../../core/search/search_index.dart';
import '../../../core/search/snippet.dart';
import '../../library/data/library_repository.dart';

/// One result row, ready to show. [snippet] is cut from the original text.
class SearchResultView {
  const SearchResultView({
    required this.hit,
    required this.saintTitle,
    required this.sectionTitle,
    required this.snippet,
  });

  final SearchHit hit;
  final String saintTitle;
  final String sectionTitle;
  final SearchSnippet snippet;

  IndexedParagraph get paragraph => hit.paragraph;
}

class SearchResponse {
  const SearchResponse({
    required this.tokens,
    required this.total,
    required this.results,
  });

  final List<String> tokens;
  final int total;
  final List<SearchResultView> results;
}

/// Builds the search index from the installed book on first use (all saint
/// files are read once), then answers queries offline. Failures are not
/// cached, so a retry rebuilds.
class SearchRepository {
  SearchRepository(this._library);

  final LibraryRepository _library;
  Future<SearchIndex>? _building;
  SearchIndex? _built;

  bool get isBuilt => _built != null;

  Future<SearchIndex> index() {
    final existing = _building;
    if (existing != null) return existing;
    final future = _build();
    _building = future;
    future.catchError((Object _) {
      _building = null;
      return SearchIndex();
    });
    return future;
  }

  Future<SearchIndex> _build() async {
    final index = SearchIndex();
    for (final entry in await _library.saints()) {
      index.addSaint(await _library.saint(entry.id));
      // Let the UI breathe between saints.
      await Future<void>.delayed(Duration.zero);
    }
    index.finalize();
    _built = index;
    return index;
  }

  Future<SearchResponse> search(String query, {int limit = 100}) async {
    final index = await this.index();
    final found = index.search(query, limit: limit);
    final results = <SearchResultView>[];
    for (final hit in found.hits) {
      final p = hit.paragraph;
      final saint = await _library.saint(p.saintId);
      Section? section;
      Paragraph? paragraph;
      for (final s in saint.sections) {
        if (s.id != p.sectionId) continue;
        section = s;
        for (final para in s.paragraphs) {
          if (para.id == p.paragraphId) paragraph = para;
        }
      }
      if (section == null || paragraph == null) continue;
      results.add(SearchResultView(
        hit: hit,
        saintTitle: saint.title,
        sectionTitle: section.title,
        snippet: buildSnippet(paragraph.text, found.tokens),
      ));
    }
    return SearchResponse(
      tokens: found.tokens,
      total: found.total,
      results: results,
    );
  }
}
