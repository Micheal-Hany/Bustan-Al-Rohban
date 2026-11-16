/// Text that is NOT part of the original book (summaries, notes). Always shown
/// visually apart from the original text. Real insights arrive in Task 7.
class EditorialAddition {
  const EditorialAddition({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}

abstract class EditorialSource {
  List<EditorialAddition> forSection(String saintId, String sectionId);
}

class NoEditorialSource implements EditorialSource {
  const NoEditorialSource();

  @override
  List<EditorialAddition> forSection(String saintId, String sectionId) =>
      const [];
}

/// Only used for FAKE (fixture) books so the distinct styling can be seen
/// before real insights exist.
class FakeEditorialSource implements EditorialSource {
  const FakeEditorialSource();

  @override
  List<EditorialAddition> forSection(String saintId, String sectionId) => [
        EditorialAddition(
          id: 'fake-ins-$sectionId',
          title: '[تجريبي] إضافة تحريرية',
          body: 'هذا نص تحريري تجريبي وليس من الكتاب.',
        ),
      ];
}
