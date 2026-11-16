import '../../../app/strings.dart';
import '../../../core/content/content_issue.dart';
import '../data/library_repository.dart';

enum LoadStatus { loading, loaded, empty, error }

/// Short text for the error view. Technical detail (an issue code and
/// message) is shown only for content validation errors.
String describeError(Object error) {
  if (error is ContentValidationException) {
    final errors = error.report.errors;
    if (errors.isEmpty) return AppStrings.loadFailed;
    return '${errors.first.code}: ${errors.first.message}';
  }
  if (error is SaintNotFoundException) return AppStrings.notFound;
  return AppStrings.unexpectedError;
}
