import 'content_issue.dart';
import 'content_models.dart';
import 'content_source.dart';
import 'content_validator.dart';
import '../../features/insights/domain/insight.dart';

class LoadedBook {
  const LoadedBook(this.book, this.warnings);

  final ContentBook book;
  final List<ContentIssue> warnings;
}

/// Loads and validates content from a [ContentSource]. Throws
/// [ContentValidationException] (with the full report) on any error.
class ContentLoader {
  ContentLoader(this.source, {ContentValidator? validator})
      : _validator = validator ?? const ContentValidator();

  final ContentSource source;
  final ContentValidator _validator;

  Future<String?> _tryRead(String path) async {
    try {
      return await source.readString(path);
    } catch (_) {
      return null;
    }
  }

  ContentIssue _missing(String file) => ContentIssue(
        severity: IssueSeverity.error,
        code: 'missing-file',
        file: file,
        message: 'File "$file" could not be read.',
      );

  Future<ContentManifest> loadManifest() async {
    final text = await _tryRead('manifest.json');
    if (text == null) {
      throw ContentValidationException(
          ValidationReport([_missing('manifest.json')]));
    }
    final parsed = _validator.parseManifest(text);
    final manifest = parsed.manifest;
    if (manifest == null) {
      throw ContentValidationException(ValidationReport(parsed.issues));
    }
    return manifest;
  }

  /// Loads and validates one saint file (used for on-demand loading).
  Future<Saint> loadSaint(SaintEntry entry) async {
    final text = await _tryRead(entry.file);
    if (text == null) {
      throw ContentValidationException(
          ValidationReport([_missing(entry.file)]));
    }
    final parsed = _validator.parseSaint(text, file: entry.file);
    final issues = [
      ...parsed.issues,
      ..._validator.duplicateIssues(parsed.ids),
    ];
    final saint = parsed.saint;
    if (saint == null || issues.any((i) => i.isError)) {
      throw ContentValidationException(ValidationReport(issues));
    }
    if (saint.id != entry.id) {
      throw ContentValidationException(ValidationReport([
        ContentIssue(
          severity: IssueSeverity.error,
          code: 'id-mismatch',
          file: entry.file,
          message: 'File id "${saint.id}" differs from the manifest id '
              '"${entry.id}".',
        ),
      ]));
    }
    return saint;
  }

  /// Loads and fully validates the whole book (manifest, all saint files,
  /// cross-file rules and the content hash).
  Future<LoadedBook> loadBook({bool allowFixture = true}) async {
    final manifestText = await _tryRead('manifest.json');
    if (manifestText == null) {
      throw ContentValidationException(
          ValidationReport([_missing('manifest.json')]));
    }
    final parsed = _validator.parseManifest(manifestText);
    final manifest = parsed.manifest;
    if (manifest == null) {
      throw ContentValidationException(ValidationReport(parsed.issues));
    }

    final files = <String, String>{};
    for (final entry in manifest.saints) {
      final text = await _tryRead(entry.file);
      if (text != null) files[entry.file] = text;
    }

    final result = _validator.validateBook(
      manifestJson: manifestText,
      saintJsonByFile: files,
      allowFixture: allowFixture,
    );
    final book = result.book;
    if (book == null) throw ContentValidationException(result.report);
    return LoadedBook(book, result.report.warnings);
  }

  /// Loads the optional insights file of a saint (`insights/<id>.insights.json`).
  /// A missing file simply means "no insights" (empty, no issues).
  Future<InsightParseResult> loadInsights(Saint saint) async {
    final file = 'insights/${saint.id}.insights.json';
    final text = await _tryRead(file);
    if (text == null) return const InsightParseResult([], []);
    return parseInsights(text, saint, file: file);
  }
}
