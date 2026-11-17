/// A saved place in the book: paragraph ID plus a character offset in it.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.saintId,
    required this.sectionId,
    required this.paragraphId,
    required this.offset,
    required this.contentVersion,
    required this.createdAt,
  });

  final String id;

  /// Hints only; the paragraph ID is the identity.
  final String saintId;
  final String sectionId;
  final String paragraphId;

  /// Character offset inside the paragraph (0 = paragraph start).
  final int offset;
  final int contentVersion;
  final DateTime createdAt;

  @override
  String toString() => 'Bookmark($id, $paragraphId+$offset)';
}

typedef IdGenerator = String Function();
typedef Clock = DateTime Function();
