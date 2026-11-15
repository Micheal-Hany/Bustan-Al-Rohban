import 'package:flutter_bloc/flutter_bloc.dart';

import '../content_issue.dart';
import '../content_loader.dart';
import '../content_models.dart';
import '../content_source.dart';

enum PreviewStatus { loading, loaded, failed }

class ContentPreviewState {
  const ContentPreviewState({
    required this.status,
    this.book,
    this.issues = const [],
    this.showingInvalid = false,
  });

  final PreviewStatus status;
  final ContentBook? book;

  /// Warnings when loaded, errors (and warnings) when failed.
  final List<ContentIssue> issues;
  final bool showingInvalid;
}

/// Debug-only preview of the installed content and of validation errors.
class ContentPreviewCubit extends Cubit<ContentPreviewState> {
  ContentPreviewCubit({
    required this.validSource,
    required this.invalidSource,
  }) : super(const ContentPreviewState(status: PreviewStatus.loading));

  final ContentSource validSource;
  final ContentSource invalidSource;

  Future<void> loadValid() => _load(validSource, invalid: false);

  Future<void> loadInvalid() => _load(invalidSource, invalid: true);

  Future<void> _load(ContentSource source, {required bool invalid}) async {
    emit(ContentPreviewState(
      status: PreviewStatus.loading,
      showingInvalid: invalid,
    ));
    try {
      final loaded = await ContentLoader(source).loadBook();
      emit(ContentPreviewState(
        status: PreviewStatus.loaded,
        book: loaded.book,
        issues: loaded.warnings,
        showingInvalid: invalid,
      ));
    } on ContentValidationException catch (e) {
      emit(ContentPreviewState(
        status: PreviewStatus.failed,
        issues: e.report.issues,
        showingInvalid: invalid,
      ));
    }
  }
}
