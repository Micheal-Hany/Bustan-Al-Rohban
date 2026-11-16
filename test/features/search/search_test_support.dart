import 'package:bustan_al_rohban/features/search/data/search_repository.dart';

import '../../core/content/test_support.dart';
import '../library/library_test_support.dart';

const vowelledText = 'السَّلَامُ عَلَيْكُمْ، رَحْمَةُ اللَّهِ وَبَرَكَاتُهُ';

/// Two saints with varied Arabic text (vowelled, alef variants, a heading).
TestBook searchBook() => buildBook([
      saintJson(
        id: 'saint-a',
        order: 1,
        title: 'القديس الأول',
        sections: [
          sectionJson(
            id: 'sec-a-001',
            order: 1,
            title: 'القسم الأول',
            paragraphs: [
              paraJson(id: 'p-000001', order: 1, page: 1, text: vowelledText),
              paraJson(
                  id: 'p-000002',
                  order: 2,
                  page: 1,
                  text: 'أبونا الأنبا أنطونيوس سكن في البرية'),
              paraJson(
                  id: 'p-000003',
                  order: 3,
                  page: 2,
                  kind: 'heading',
                  text: 'رحمة الله'),
            ],
          ),
          sectionJson(
            id: 'sec-a-002',
            order: 2,
            title: 'القسم الثاني',
            paragraphs: [
              paraJson(
                  id: 'p-000004',
                  order: 1,
                  page: 3,
                  text: 'قال الرب لموسى كلمة'),
            ],
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
            order: 1,
            title: 'قسم ب',
            paragraphs: [
              paraJson(
                  id: 'p-000005',
                  order: 1,
                  page: 5,
                  text: 'محبة الله رحمته على الجميع'),
              paraJson(
                  id: 'p-000006',
                  order: 2,
                  page: null,
                  text: 'إبونا يصلي بلا انقطاع'),
            ],
          ),
        ],
      ),
    ]);

SearchRepository searchRepoFor(ProbeSource source) =>
    SearchRepository(repoFor(source));
