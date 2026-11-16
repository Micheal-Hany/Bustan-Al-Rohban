import 'dart:async';

import 'package:bustan_al_rohban/core/content/content_loader.dart';
import 'package:bustan_al_rohban/core/content/content_source.dart';
import 'package:bustan_al_rohban/features/library/data/library_repository.dart';

import '../../core/content/test_support.dart';

/// Counts reads per path and can hold reads until [release] is called.
class ProbeSource implements ContentSource {
  ProbeSource(this.inner);

  final ContentSource inner;
  final Map<String, int> reads = {};
  Completer<void>? gate;

  @override
  Future<String> readString(String relativePath) async {
    reads[relativePath] = (reads[relativePath] ?? 0) + 1;
    final g = gate;
    if (g != null) await g.future;
    return inner.readString(relativePath);
  }

  void hold() => gate = Completer<void>();

  void release() {
    gate?.complete();
    gate = null;
  }
}

/// Two saints. The manifest validator requires them listed in order
/// (order 1, then 2), so the book is valid.
TestBook twoSaintBook() => buildBook([
      saintJson(
        id: 'saint-a',
        order: 1,
        title: 'القديس الأول',
        sections: [
          sectionJson(
            id: 'sec-a-001',
            title: 'قسم أ ١',
            paragraphs: [
              paraJson(id: 'p-000001', order: 1, page: 3),
              paraJson(id: 'p-000002', order: 2, page: 5, text: 'نص آخر'),
            ],
          ),
          sectionJson(
            id: 'sec-a-002',
            order: 2,
            title: 'قسم أ ٢',
            paragraphs: [paraJson(id: 'p-000003', page: null)],
          ),
        ],
      ),
      saintJson(
        id: 'saint-b',
        order: 2,
        title: 'القديس الثاني',
        sections: [
          sectionJson(
            id: 'sec-b-001',
            title: 'قسم ب',
            paragraphs: [paraJson(id: 'p-000004', text: 'نص ب')],
          ),
        ],
      ),
    ]);

ProbeSource probeFor(TestBook book) =>
    ProbeSource(InMemoryContentSource({
      'manifest.json': book.manifestJson,
      ...book.files,
    }));

LibraryRepository repoFor(ProbeSource source) =>
    LibraryRepository(ContentLoader(source));
